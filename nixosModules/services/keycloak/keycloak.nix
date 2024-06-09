/**
  Sandbox keycloak
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
      # set proxy to edge maybe?
    };
    database.passwordFile = config.age.secrets."keycloakDbPassword".path;
  };
}
