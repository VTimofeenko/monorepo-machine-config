{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.tailscale;
in
{
  services.tailscale = {
    enable = true;
    authKeyFile = config.age.secrets.tailscale.path;
    useRoutingFeatures = "server";
    extraUpFlags = [
      "--netfilter-mode=nodivert" # Disable firewall management
    ];
  };

  # Patch to force use of command line flags. Takes logic from 25.11 and
  # applies to nixpkgs stable.

  # FIXME: remove this if connect OK

  # systemd.services.tailscaled-autoconnect = {
  #   serviceConfig = {
  #     Type = lib.mkForce "notify";
  #   };
  #   path = [
  #     cfg.package
  #     pkgs.jq
  #   ];
  #   enableStrictShellChecks = true;
  #
  #   script =
  #     let
  #       paramToString = v: if (builtins.isBool v) then (lib.boolToString v) else (toString v);
  #       params = lib.pipe cfg.authKeyParameters [
  #         (lib.filterAttrs (_: v: v != null))
  #         (lib.mapAttrsToList (k: v: "${k}=${paramToString v}"))
  #         (builtins.concatStringsSep "&")
  #         (params: if params != "" then "?${params}" else "")
  #       ];
  #     in
  #     lib.mkForce
  #       # bash
  #       ''
  #         getState() {
  #           tailscale status --json --peers=false | jq -r '.BackendState'
  #         }
  #
  #         lastState=""
  #         while state="$(getState)"; do
  #           if [[ "$state" != "$lastState" ]]; then
  #             # https://github.com/tailscale/tailscale/blob/v1.72.1/ipn/backend.go#L24-L32
  #             case "$state" in
  #               NeedsLogin|NeedsMachineAuth|Stopped|NoState)
  #                 echo "$0"
  #                 echo "Server needs authentication, sending auth key"
  #                 tailscale up --auth-key "$(cat ${cfg.authKeyFile})${params}" ${lib.escapeShellArgs cfg.extraUpFlags}
  #                 ;;
  #               Running)
  #                 echo "Tailscale is running"
  #                 systemd-notify --ready
  #                 exit 0
  #                 ;;
  #               *)
  #                 echo "Waiting for Tailscale State = Running or systemd timeout"
  #                 ;;
  #             esac
  #             echo "State = $state"
  #           fi
  #           lastState="$state"
  #           sleep .5
  #         done
  #       '';
  # };
}
