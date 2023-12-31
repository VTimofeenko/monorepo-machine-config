/* NixOS module to configure PostgreSQL backend for all services at home */
{ config
, lib
, pkgs
, localLib
, ...
}:

let
  inherit (config) my-data;
  # srvName = "db";
  # service = my-data.lib.getService srvName;

  dbNet = my-data.lib.getNetwork "db";
  mgmtNet = my-data.lib.getNetwork "mgmt";

  luks = {
    device_name = "luks_db";
    UUID = "1e4cc767-a3f7-4990-9398-27670aed1a29";
  };
in
{
  /* Secrets */ # TODO: not reuse the ssl-terminator secret here?
  age.secrets."ssl-cert" = {
    file = my-data.lib.getSrvSecret "ssl-terminator" "cert";
    owner = "postgres";
  };
  age.secrets."ssl-key" = {
    file = my-data.lib.getSrvSecret "ssl-terminator" "private-key";
    owner = "postgres";
  };

  /* Service configuration */
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_14; # TODO: Migrate to 15
    enableTCPIP = true;
    ensureUsers = [{
      name = "sysop";
      ensureClauses.superuser = true;
    }];
    settings = {
      ssl = "on";
      ssl_cert_file = config.age.secrets.ssl-cert.path;
      ssl_key_file = config.age.secrets.ssl-key.path;
      /* Listen only on these addresses */
      listen_addresses = lib.mkForce
        (lib.concatStringsSep
          ", "
          (map (netName: (my-data.lib.getOwnHostInNetwork netName).ipAddress) [ "mgmt" "db" ]));
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
  networking.firewall.allowedTCPPorts = [ config.services.postgresql.port ];

  /* DB configuration for services */
  imports =
    map
      (srvName: {
        services.postgresql = {
          ensureDatabases = [ srvName ];
          ensureUsers = [{ name = srvName; ensureDBOwnership = true; }];
        };
      })
      [ "tt_rss" "nextcloud" "docspell" ]; # TODO: Generate these in data-flake

  /* LUKS setup */
  systemd.services.postgresql.unitConfig.RequiresMountsFor = lib.mkOptionDefault [ config.services.postgresql.dataDir ];
  environment.etc."crypttab".text = localLib.mkCryptTab { inherit (luks) device_name UUID; };
  systemd.mounts =
    [
      (localLib.mkLuksMount {
        inherit (luks) device_name;
        target = config.services.postgresql.dataDir;
      })
    ];
}
