# NixOS module to configure PostgreSQL backend for all services at home
{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib.homelab) getNetwork;

  dbNet = getNetwork "db";
  mgmtNet = getNetwork "mgmt";
in
{
  # Secrets
  age.secrets.psql-ssl-cert = {
    inherit (config.age.secrets.ssl-cert) file;
    owner = config.systemd.services.postgresql.serviceConfig.User;
    group = config.systemd.services.postgresql.serviceConfig.Group;
  };
  age.secrets.psql-ssl-key = {
    inherit (config.age.secrets.ssl-key) file;
    owner = config.systemd.services.postgresql.serviceConfig.User;
    group = config.systemd.services.postgresql.serviceConfig.Group;
  };

  # Service configuration
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_14; # TODO: Migrate to 15
    enableTCPIP = true;
    ensureUsers = [
      {
        name = "sysop";
        ensureClauses.superuser = true;
      }
      {
        name = "pgadmin";
        ensureClauses.superuser = true;
      }
    ];
    settings = {
      ssl = "on";
      ssl_cert_file = config.age.secrets.psql-ssl-cert.path;
      ssl_key_file = config.age.secrets.psql-ssl-key.path;
    };
    authentication = ''
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      # Secure sysop login
      hostssl    all             sysop           ${mgmtNet.settings.managementNodesSubNet}.0/24             scram-sha-256
      hostssl    all             sysop           all                     reject

      # DB network
      host    all             all             ${dbNet.subnet}.0/24          scram-sha-256
    '';
  };

  # DB configuration for services
  imports =
    map
      (srvName: {
        services.postgresql = {
          ensureDatabases = [ srvName ];
          ensureUsers = [
            {
              name = srvName;
              ensureDBOwnership = true;
            }
          ];
        };
      })
      [
        "nextcloud"
        "docspell"
      ]; # TODO: Generate these in manifests
}
