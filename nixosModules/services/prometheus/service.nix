{ lib, config, ... }:
let
  srvName = "prometheus";
  inherit (lib) pipe;
  inherit (lib.homelab) getHostIpInNetwork;
  exporters = [
    "node"
    "systemd"
    "smartctl"
  ];
in
{
  services.prometheus = {
    enable = true;
    retentionTime = "30d";
    scrapeConfigs = pipe exporters [
      (map (x: {
        job_name = x;
        scrape_interval = "30s";
        static_configs = pipe [ "fluorine" ] [
          (map (
            nodeName:
            let
              # FIXME: DNS
              ip = getHostIpInNetwork nodeName "monitoring";
            in
            {
              targets = [ "${ip}:${toString config.services.prometheus.exporters.${x}.port}" ];
              labels.alias = "${nodeName}.home.arpa";
            }
          ))

        ];
      }))
    ];
  };

  # Mounts
  systemd = {
    # Reconstruct the workdir
    services.prometheus.unitConfig.RequiresMountsFor = [
      "/var/lib/${config.services.prometheus.stateDir}"
    ];
    mounts = [
      {
        what = "/dev/disk/by-label/${srvName}";
        where = "/var/lib/${config.services.prometheus.stateDir}";
        options = "noatime";
      }
    ];
  };

}
