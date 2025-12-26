{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.homelab) getServiceConfig getServiceFqdn getSrvSecret;
  srvName = "nextcloud";
in
{
  # Service configuration
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud31;
    hostName = getServiceFqdn srvName;

    configureRedis = true;

    config = {
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbhost = getServiceFqdn "db";
      dbname = "nextcloud";
      dbpassFile = config.age.secrets.dbpassFile.path;
      adminuser = "root";
      adminpassFile = config.age.secrets.adminpassFile.path;
    };
    settings = getServiceConfig srvName // {
      overwriteprotocol = "https";
      mail_smtpauth = true;
      mail_smtpport = 465;
    };

    secretFile = config.age.secrets.nextcloudSecrets.path;
  };

  imports = lib.localLib.mkImportsFromDir ./functional;

  # Secrets
  age.secrets =
    let
      nextcloudUsr = config.systemd.services.nextcloud-setup.serviceConfig.User;
    in
    {
      dbpassFile = {
        file = getSrvSecret srvName "dbpassFile";
        owner = nextcloudUsr;
        group = nextcloudUsr;
      };
      adminpassFile = {
        file = getSrvSecret srvName "adminpassFile";
        owner = nextcloudUsr;
        group = nextcloudUsr;
      };
      nextcloudSecrets = {
        file = getSrvSecret srvName "nextcloudSecrets";
        owner = nextcloudUsr;
        group = nextcloudUsr;
      };
    };

  # LUKS setup
}
