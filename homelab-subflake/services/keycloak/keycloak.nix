{ config, lib, ... }:
let
  srvName = "keycloak";
in
{
  services.keycloak = {
    enable = true;

    sslCertificate = config.age.secrets.ssl-cert.path;
    sslCertificateKey = config.age.secrets.ssl-key.path;
  };

  # The cert is copied in via `LoadCredential` at start and there is no
  # `ExecReload`, so a renewed cert needs a restart.
  systemd.services.keycloak.restartTriggers = [
    (builtins.hashFile "sha256" config.age.secrets.ssl-cert.rekeyFile)
  ];

  services.keycloak = {

    settings = {
      hostname = srvName |> lib.homelab.getServiceFqdn;
    };
    database.passwordFile = config.age.secrets.keycloak-db-password.path;
  };
}
