{ lib, config, ... }:
let
  srvName = "prometheus";
  inherit (lib) pipe;
  inherit (lib.homelab) getHostInNetwork getServiceConfig getServiceIP;
  inherit (getServiceConfig "prometheus") exporters;
in
{
  services.prometheus = {
    enable = true;
    retentionTime = "30d";
    listenAddress = getServiceIP srvName;
    scrapeConfigs = pipe exporters [
      (map (x: {
        job_name = x;
        scrape_interval = "30s";
        static_configs = pipe config.my-data.services.all.monitoring-source.onHosts [
          (map (nodeName: {
            targets = [
              "${(getHostInNetwork nodeName "monitoring").fqdn}:${
                toString config.services.prometheus.exporters.${x}.port
              }"
            ];
            labels.alias = "${nodeName}.home.arpa";
          }))
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

  imports = [
    ./synology
    ./service-scraping
    ./healthchecks-scraping.nix
  ];
}
