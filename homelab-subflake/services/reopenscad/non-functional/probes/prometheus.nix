/**
  ReOpenSCAD has no metrics; probe its `/api/health` through the shared
  blackbox exporter. It is a static reply, so this only catches the process
  not answering, not a lost database connection.

  The server answers 403 to any Host header but its public origin, so the
  probe sends that one while connecting to the inner IP.
*/
{ lib, ... }:
let
  serviceName = "reopenscad";
  inherit (lib.homelab.getManifest serviceName) endpoints;
  module = "http_2xx_${serviceName}";
in
{
  services.homelab.blackbox.modules.${module} = {
    prober = "http";
    timeout = "5s";
    http = {
      headers.Host = lib.homelab.getServiceFqdn serviceName;
      fail_if_body_not_matches_regexp = [ ''"ok":true'' ];
    };
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "${serviceName}-health-probe";
      metrics_path = "/probe";
      params.module = [ module ];
      static_configs = [
        {
          targets = [
            "http://${lib.homelab.getServiceInnerIP serviceName}:${toString endpoints.web.port}/api/health"
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
