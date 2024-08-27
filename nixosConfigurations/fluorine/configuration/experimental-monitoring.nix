{ config, lib, ... }:
let
  inherit (lib) pipe;
  listenAddress = lib.homelab.getOwnIpInNetwork "monitoring";
  # TODO: move to module settings?
  exporters = [
    "node"
    "systemd"
    "smartctl"
  ];
in
{
  imports = [ ./collect-nixos-version.nix ];
  # This is the generic per adapter firewall
  # Maybe adapt it to module?
  # networking.firewall.interfaces = pipe (getService srvName) [
  #   (builtins.getAttr "networkAccess") # -> ["lan" "client"]
  #   (map (network: getOwnHost.networks.${network}.adapter or network)) # -> ["eth0" "client"]
  #   (map (interface: {
  #     name = interface;
  #     value.allowedTCPPorts = [ config.services.${srvName}.port ];
  #   }))
  #   builtins.listToAttrs
  # ];

  networking.firewall.interfaces.monitoring.allowedTCPPorts = pipe exporters [
    (map (x: config.services.prometheus.exporters.${x}.port))
  ];

  services.prometheus.exporters =
    # Enable exporters with standard options
    pipe
      (pipe exporters [
        (map (x: {
          name = x;
          value = {
            enable = true;
            inherit listenAddress;
          };
        }))
        builtins.listToAttrs
      ])
      [
        # not // to preserve enable and stuff
        (lib.recursiveUpdate {
          node = {
            enabledCollectors = [
              "conntrack"
              "diskstats"
              "filesystem"
              "loadavg"
              "meminfo"
              "netdev"
              "netstat"
              "stat"
              "time"
              "systemd"
              "hwmon"
              "processes"
            ];
            extraFlags = [ "--collector.textfile.directory=/var/run/node_exporter_text" ];
          };
        })
      ];

  # W/a to allow nvme devices access
  # Source: https://github.com/NixOS/nixpkgs/issues/210041 and linked PRs
  users.groups.rawio = { };
  services.udev.extraRules = ''
    SUBSYSTEM=="nvme", KERNEL=="nvme[0-9]*", GROUP="rawio"
  '';
  systemd.services."prometheus-smartctl-exporter".serviceConfig.SupplementaryGroups = [
    "disk"
    "rawio"
  ];
}
