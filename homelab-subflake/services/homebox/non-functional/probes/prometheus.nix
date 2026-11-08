/**
  Homebox has no metrics; probe the OIDC login endpoint through the shared
  blackbox exporter. It redirects (302) to Keycloak only when the OIDC provider
  initialized; otherwise it returns 500 while the rest of the app looks healthy.
  Local login is disabled, so this is the only way in.
*/
{ lib, ... }:
let
  serviceName = "homebox";
  inherit (lib.homelab.getManifest serviceName) endpoints;
in
{
  services.homelab.blackbox.modules.homebox_oidc_login = {
    prober = "http";
    timeout = "5s";
    http = {
      follow_redirects = false;
      valid_status_codes = [ 302 ];
    };
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "${serviceName}-oidc-login-probe";
      metrics_path = "/probe";
      params.module = [ "homebox_oidc_login" ];
      static_configs = [
        {
          targets = [
            "http://${lib.homelab.getServiceInnerIP serviceName}:${toString endpoints.web.port}/api/v1/users/login/oidc"
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
