{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.homelab) getServiceConfig getServiceFqdn getSrvSecret;
  inherit (lib.localLib) mkCryptTab mkLuksMount;

  srvName = "nextcloud";

  luks = {
    device_name = "luks_nextcloud";
    UUID = "0523d6c9-9ea5-4296-85a2-5655189fd0b5";
  };
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
    };

    secretFile = config.age.secrets.nextcloudSecrets.path;
  };

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
  systemd.services.nextcloud-setup.unitConfig.RequiresMountsFor = [ config.services.nextcloud.home ];

  environment.etc."crypttab".text = mkCryptTab { inherit (luks) device_name UUID; };
  systemd.mounts = [
    (mkLuksMount {
      inherit (luks) device_name;
      target = config.services.nextcloud.home;
    })
  ];
}
