/**
  Makes nginx refuse answering when the client asks for a nonexistent virtual host.
*/
{ config, ... }:
{
  services.nginx.virtualHosts."_" = {
    forceSSL = true;
    inherit (config.services.homelab.ssl-proxy) listenAddresses;
    sslCertificate = config.age.secrets."ssl-cert".path;
    sslCertificateKey = config.age.secrets."ssl-key".path;
    extraConfig = "return 444;";
  };
}
