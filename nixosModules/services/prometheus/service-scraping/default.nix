# Scrapes the individual services metrics
{ lib, config, ... }:
let
  inherit (lib.homelab) getHostIpInNetwork;
in
{
  services.prometheus.scrapeConfigs = lib.pipe config.my-data.services.all [
    (lib.filterAttrs (_: v: v ? monitoring && v.monitoring.enable && v.monitoring ? scrapeUrl))
    # Extract the service <> scrapeUrl
    # Implementation note: technically all values don't need these functions but this will survive interface
    # changes
    (builtins.mapAttrs (
      srvName: v: {
        job_name = "${srvName}-srv-scrape";
        scrape_interval = "30s";
        static_configs = [
          {
            targets = lib.pipe srvName [
              # Try http
              lib.homelab.getServiceFqdn
              # Fall back to non http
              (
                x:
                let
                  ipAddress = getHostIpInNetwork v.onHost "monitoring";
                  scrapePort = config.services.prometheus.exporters.${v.monitoring.exporterNixOption}.port;
                in
                if x == null then "${ipAddress}:${toString scrapePort}" else x
              )
              lib.singleton
            ];
          }
        ];
        metrics_path =
          v.monitoring.scrapeUrl
            or config.services.prometheus.exporters.${v.monitoring.exporterNixOption}.telemetryPath;
        bearer_token = (lib.homelab.getServiceConfig srvName).metricsToken or "";
      }
    ))
    builtins.attrValues
  ];
}
