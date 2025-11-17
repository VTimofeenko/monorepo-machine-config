{ lib, ... }:
let
  inherit (lib) pipe;
  inherit (lib.homelab) getServiceConfig;
  listenAddress =
    if lib.homelab.amInNetwork "monitoring" then
      lib.homelab.getOwnIpInNetwork "monitoring"
    else
      lib.homelab.getOwnIpInNetwork "backbone-inner";
  inherit (getServiceConfig "prometheus") exporters;
in
{
  imports = [ ./collect-nixos-version.nix ];

  # lib.mkMerge is effectively here:
  # lib.foldl lib.recursiveUpdate { }
  services.prometheus.exporters = lib.mkMerge [
    # Enable exporters with standard options
    #
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
    {
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
    }
    {
      systemd.extraFlags = [
        "--systemd.collector.enable-restart-count"
        "--systemd.collector.enable-ip-accounting"
      ];

    }
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
