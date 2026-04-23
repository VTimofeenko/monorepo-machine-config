{ serviceName, ... }:
{ config, lib, self, ... }:
let
  inherit (lib.homelab.getManifest serviceName) endpoints;
in
{
  imports = [
    (self.serviceModules.ssl-proxy.srvLib.mkStandardProxyVHost {
      inherit serviceName config lib;
      inherit (endpoints.web) port;
    })
  ];

  # Webhook path proxied directly to `fava-helper`, bypassing SSO so Gitea can
  # reach it without authentication.
  services.nginx.virtualHosts.${lib.homelab.getServiceFqdn serviceName}.locations."/webhook" = {
    proxyPass = "http://${lib.homelab.getServiceInnerIP serviceName}:${
      endpoints.webhook.port |> toString
    }/webhook";
    extraConfig = ''auth_request off;'';
  };
}
