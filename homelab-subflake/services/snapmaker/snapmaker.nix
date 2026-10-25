{ lib, pkgs, ... }:
let
  srvName = "snapmaker";
  printer = lib.homelab.getHostInNetwork "snapmaker-u1" "iot";

  # Moonraker sees connections from this host's LAN address (default route
  # towards the IoT VLAN)
  printerConfig = import ./printer-config {
    inherit lib;
    relayHostIP = lib.homelab.getOwnIpInNetwork "lan"; # TODO: if moving to balanced SSL proxy, will need to change this
  };

  configDir = printerConfig.files |> lib.mapAttrs (path: pkgs.writeText (baseNameOf path)) |> pkgs.linkFarm "snapmaker-config";
in
{
  services.nginx.virtualHosts = {
    snapmaker-relay-web = {
      locations."/" = {
        proxyPass = "http://${printer.ipAddress}";
        proxyWebsockets = true;
      };
      extraConfig = "client_max_body_size 1G;";
    };
    snapmaker-relay-metrics.locations."/".proxyPass = "http://${printer.ipAddress}:9101";
  };

  /**
    Pushes `printer-config` through Moonraker's file API via the public vhost
    (Moonraker only trusts this host). Restarts Moonraker or reboots the
    printer depending on what changed. Refuses to run mid-print.

    ```
    nix run .#nixosConfigurations.<host>.config.system.build.snapmaker-push [-- --reboot]
    ```
  */
  system.build.snapmaker-push = pkgs.writeShellApplication {
    name = "snapmaker-push";
    runtimeInputs = with pkgs; [
      curl
      jq
      diffutils
    ];
    text = ''
      base="https://${lib.homelab.getServiceFqdn srvName}"
      api() { curl -fsS "$@"; }

      state=$(api "$base/printer/objects/query?print_stats" | jq -r .result.status.print_stats.state)
      case "$state" in
        printing | paused) echo "Printer is $state, not pushing"; exit 1 ;;
      esac

      # `--reboot` forces a reboot, e.g. when a previous push uploaded but failed to apply
      need_reboot=0
      [ "''${1:-}" = "--reboot" ] && need_reboot=1
      need_restart=0
      cd ${configDir}
      for path in ${printerConfig.files |> builtins.attrNames |> lib.escapeShellArgs}; do
        current=$(mktemp)
        api "$base/server/files/config/$path" -o "$current" 2>/dev/null || true
        if diff -u --label "printer:$path" --label "nix:$path" "$current" "$path"; then
          rm "$current"
          continue
        fi
        rm "$current"
        api -o /dev/null "$base/server/files/upload" \
          -F root=config -F "path=$(dirname "$path")" -F "file=@$path;filename=$(basename "$path")"
        case "$path" in
          extended/extended2.cfg) need_reboot=1 ;;
          *) need_restart=1 ;;
        esac
      done

      # Stale managed includes
      for path in $(api "$base/server/files/list?root=config" | jq -r '.result[].path | select(startswith("${printerConfig.managedPrefix}"))'); do
        if [ ! -e "$path" ]; then
          echo "Removing stale $path"
          api -o /dev/null -X DELETE "$base/server/files/config/$path"
          need_restart=1
        fi
      done

      # Moonraker runs without a system provider here, so its own
      # /machine/reboot and /server/restart do nothing. Firmware-config
      # actions call the init scripts directly.
      if [ "$need_reboot" = 1 ]; then
        echo "Rebooting printer"
        api -X POST "$base/firmware-config/api/action/reboot-system"
      elif [ "$need_restart" = 1 ]; then
        echo "Restarting Moonraker"
        api -X POST "$base/firmware-config/api/action/restart-moonraker"
      else
        echo "Printer config is up to date"
      fi
    '';
  };
}
