{ lib, ... }:
let
  inherit (lib) pipe;
  inherit (lib.homelab) getServiceConfig;
  listenAddress = lib.homelab.getOwnIpInNetwork "monitoring";
  inherit (getServiceConfig "prometheus") exporters;
in
{
  imports = [ ./collect-nixos-version.nix ];

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
