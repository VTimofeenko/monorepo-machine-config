/**
  Probes keycloak's own SSL certificate via `srv:ssl-proxy`'s ssl-exporter.
  Keycloak manages its own cert (centralSSL = false), so it gets a dedicated probe job.
*/
{ lib, ... }:
{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "ssl-probe-keycloak";
      metrics_path = "/probe";
      scheme = "https";
      static_configs = [
        {
          targets = [ "${lib.homelab.getServiceFqdn "keycloak"}:443" ];
          labels = {
            cert_type = "own";
            resource = "srv:keycloak";
          };
        }
      ];
      relabel_configs = [
        {
          source_labels = [ "__address__" ];
          target_label = "__param_target";
        }
        {
          source_labels = [ "__param_target" ];
          target_label = "instance";
        }
        # Reuse ssl-proxy's ssl-exporter — no exporter runs on keycloak's host
        {
          target_label = "__address__";
          replacement = lib.homelab.services.getServiceMetricsFqdn "ssl-proxy";
        }
      ];
    }
  ];
}
