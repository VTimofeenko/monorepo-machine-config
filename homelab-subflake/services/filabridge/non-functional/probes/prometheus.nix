/**
  FilaBridge has no metrics; probe its `/healthz` (200 when the service and its
  database are healthy) through the shared blackbox exporter.
*/
{ lib, ... }:
let
  serviceName = "filabridge";
  inherit (lib.homelab.getManifest serviceName) endpoints;
in
{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "${serviceName}-healthz-probe";
      metrics_path = "/probe";
      params.module = [ "http_2xx" ];
      static_configs = [
        {
          targets = [
            "http://${lib.homelab.getServiceInnerIP serviceName}:${toString endpoints.web.port}/healthz"
          ];
          labels = {
            resource = "srv:${serviceName}";
            service = serviceName;
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
        {
          target_label = "__address__";
          replacement = (lib.homelab.getSrvLib "prometheus").blackboxAddress;
        }
      ];
    }
  ];
}
