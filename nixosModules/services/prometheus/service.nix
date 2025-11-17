{ lib, config, ... }:
let
  srvName = "prometheus";
  inherit (lib) pipe;
  inherit (lib.homelab) getServiceConfig getServiceIP;
  inherit (getServiceConfig "prometheus") exporters;
in
{
  services.prometheus = {
    enable = true;
    retentionTime = "120d";
    listenAddress = getServiceIP srvName;
    scrapeConfigs = pipe exporters [
      (map (x: {
        job_name = x;
        scrape_interval = "30s";
        static_configs =
          lib.homelab.getService "monitoring-source"
          |> builtins.getAttr "onHosts"
          |> map (nodeName: {
            targets =
              let
                hostName =
                  if lib.homelab.isInNetwork nodeName "monitoring" then
                    lib.homelab.getHostIpInNetwork nodeName "monitoring"
                  else
                    lib.homelab.getHostIpInNetwork nodeName "backbone-inner";
              in
              [
                "${hostName}:${config.services.prometheus.exporters.${x}.port |> toString}"
              ];
            labels.alias = "${nodeName}.home.arpa";
          });
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
