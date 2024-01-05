{ config, pkgs, localLib, ... }:
let
  inherit (config) my-data;
  srvName = "nextcloud";

  service = my-data.lib.getService srvName;

  luks = {
    device_name = "luks_nextcloud";
    UUID = "0523d6c9-9ea5-4296-85a2-5655189fd0b5";
  };
in
{
  /* Service configuration */
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud27;
    hostName = service.fqdn;

    config = {
      dbtype = "pgsql";
      dbuser = "nextcloud";
      # Predicated on postgres running on the same host
      dbhost = (my-data.lib.getService "db").fqdn;
      dbname = "nextcloud";
      dbpassFile = config.age.secrets.dbpassFile.path;
      adminuser = "root";
      overwriteProtocol = "https";
      adminpassFile = config.age.secrets.adminpassFile.path;
    };
    extraOptions = my-data.lib.getServiceConfig srvName;

    secretFile = config.age.secrets.nextcloudSecrets.path;
  };

  /* Secrets */
  age.secrets = let nextcloudUsr = config.systemd.services.nextcloud-setup.serviceConfig.User; in {
    dbpassFile = {
      file = my-data.lib.getSrvSecret srvName "dbpassFile";
      owner = nextcloudUsr;
      group = nextcloudUsr;
    };
    adminpassFile = {
      file = my-data.lib.getSrvSecret srvName "adminpassFile";
      owner = nextcloudUsr;
      group = nextcloudUsr;
    };
    nextcloudSecrets = {
      file = my-data.lib.getSrvSecret srvName "nextcloudSecrets";
      owner = nextcloudUsr;
      group = nextcloudUsr;
    };
  };

  /* LUKS setup */
  systemd.services.nextcloud-setup.unitConfig.RequiresMountsFor = [ config.services.nextcloud.home ];

  environment.etc."crypttab".text = localLib.mkCryptTab { inherit (luks) device_name UUID; };
  systemd.mounts =
    [
      (localLib.mkLuksMount {
        inherit (luks) device_name;
        target = config.services.nextcloud.home;
      })
    ];
}
