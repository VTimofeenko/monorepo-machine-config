{ lib, ... }:
let
  # All centrally proxied services share one cert — probe one representative
  centralTarget =
    (lib.homelab.getSrvLib "ssl-proxy").getProxiedServices |> lib.head |> lib.homelab.getServiceFqdn;

  metricsFqdn = lib.homelab.services.getServiceMetricsFqdn "ssl-proxy";
in
{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "ssl-probe";
      metrics_path = "/probe";
      scheme = "https";
      static_configs = [
        {
          targets = [ "${centralTarget}:443" ];
          labels = {
            cert_type = "central";
            resource = "srv:ssl-proxy";
          };
        }
      ];
      relabel_configs = [
        # Move target FQDN into `?target=` query parameter
        {
          source_labels = [ "__address__" ];
          target_label = "__param_target";
        }
        # Preserve FQDN as human-readable instance label
        {
          source_labels = [ "__param_target" ];
          target_label = "instance";
        }
        # Route all probes through `srv:ssl-proxy` metrics virtual host
        {
          target_label = "__address__";
          replacement = metricsFqdn;
        }
      ];
    }
  ];
}
