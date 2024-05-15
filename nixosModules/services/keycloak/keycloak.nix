/**
  Sandbox keycloak
*/
{
  nixpkgs-unstable,
  pkgs,
  config,
  ...
}:
let
  pkgs-unstable = import nixpkgs-unstable { inherit (pkgs) system; }; # FIXME: remove after 24.05. keycloak is insecure in 23.11
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
    package = pkgs-unstable.keycloak;
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
