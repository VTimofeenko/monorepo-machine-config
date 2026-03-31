{ config, lib, ... }:
let
  srvName = "keycloak";
in
{
  services.keycloak = {
    enable = true;

    sslCertificate = config.age.secrets.ssl-cert.path;
    sslCertificateKey = config.age.secrets.ssl-key.path;

    settings = {
      hostname = srvName |> lib.homelab.getServiceFqdn;
    };
    database.passwordFile = config.age.secrets.keycloak-db-password.path;
  };
}
