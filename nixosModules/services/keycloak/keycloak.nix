/**
  Note: keycloak needs some SSL certificate to work. The one from
  `ssl-terminator` works for now, but later I might just switch to self-signed
  one.
*/
{ config, ... }:
let
  inherit (config) my-data;
  srvName = "keycloak";
  service = my-data.lib.getService srvName;
in
{
  age.secrets = {
    "ssl-cert".file = my-data.lib.getSrvSecret "ssl-terminator" "cert";
    "ssl-key".file = my-data.lib.getSrvSecret "ssl-terminator" "private-key";
    "keycloakDbPassword".file = my-data.lib.getSrvSecret srvName "dbPasswordFile";
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
