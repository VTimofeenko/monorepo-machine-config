/**
  Note: Keycloak needs some SSL certificate to work. The one from
  `ssl-terminator` works for now, but later I might just switch to self-signed
  one.
*/
{ config, lib, ... }:
let
  srvName = "keycloak";
  service = lib.homelab.getService srvName;
  inherit (lib.homelab) getSrvSecret;
in
{
  age.secrets = {
    "ssl-cert".file = getSrvSecret "ssl-terminator" "cert";
    "ssl-key".file = getSrvSecret "ssl-terminator" "private-key";
    "keycloakDbPassword".file = getSrvSecret srvName "dbPasswordFile";
  };

  services.keycloak = {
    enable = true;

    sslCertificate = config.age.secrets.ssl-cert.path;
    sslCertificateKey = config.age.secrets.ssl-key.path;

    settings = {
      hostname = service.fqdn;
    };
    database.passwordFile = config.age.secrets."keycloakDbPassword".path;
  };
}
