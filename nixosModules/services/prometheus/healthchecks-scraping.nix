{ lib, ... }:
let
  srvName = "prometheus";
in
{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "healthchecks";
      scrape_interval = "60s";
      metrics_path = (lib.homelab.getServiceConfig srvName).hcMainProjectMetricsURL;
      scheme = "https";
      static_configs = [ { targets = [ (lib.homelab.getServiceFqdn "healthchecks") ]; } ];
    }
  ];
}
