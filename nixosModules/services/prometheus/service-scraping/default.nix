# Scrapes the individual services metrics
{ lib, config, ... }:
{
  services.prometheus.scrapeConfigs = lib.pipe config.my-data.services.all [
    (lib.filterAttrs (_: v: v ? monitoring && v.monitoring ? scrapeUrl))
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
              lib.homelab.getServiceFqdn
              lib.singleton
            ];
          }
        ];
        metrics_path = v.monitoring.scrapeUrl;
        bearer_token = (lib.homelab.getServiceConfig srvName).metricsToken;
      }
    ))
    builtins.attrValues
  ];
}
