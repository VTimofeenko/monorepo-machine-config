{ config, lib, ... }:
let
  serviceName = "healthchecks";
  port = 8000;
in
{
  services.nginx.virtualHosts."${serviceName |> lib.homelab.getServiceFqdn}" = {
    forceSSL = true;
    inherit (config.services.homelab.ssl-proxy) listenAddresses;
    sslCertificate = config.age.secrets."ssl-cert".path;
    sslCertificateKey = config.age.secrets."ssl-key".path;
    locations."/" = {
      proxyPass = "http://${serviceName |> lib.homelab.getServiceInnerIP}:${port |> toString}";
      proxyWebsockets = true;
    };
  };
}
