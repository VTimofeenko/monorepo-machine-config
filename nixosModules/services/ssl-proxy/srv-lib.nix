/**
  A sketch of what a srvLib for SSL proxy could look like.

  TODO: pass to other modules.
*/
{ lib, ... }:
{
  mkStandardProxyVHost =
    {
      serviceName,
      port,
      config,
    }:
    {
      services.nginx.virtualHosts."${serviceName |> lib.homelab.getServiceFqdn}" = {
        forceSSL = true;
        inherit (config.services.homelab.ssl-proxy) listenAddresses;
        sslCertificate = config.age.secrets."ssl-cert".path;
        sslCertificateKey = config.age.secrets."ssl-key".path;
        locations."/" = {
          proxyPass = "http://${lib.homelab.getServiceInnerIP}:${port |> toString}";
          proxyWebsockets = true;
        };
      };
    };
}
