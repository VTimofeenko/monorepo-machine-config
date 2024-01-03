{ config, ... }:
let
  inherit (config) my-data;
  srvName = "pgadmin";
in
{
  /* Service config */
  services.pgadmin = {
    enable = true;
    initialEmail = "pgadmin@${my-data.settings.publicDomainName}";
    initialPasswordFile = "${config.age.secrets.pgadmin-password.path}";
    settings = {
      UPGRADE_CHECK_ENABLED = false;
    };
  };

  /* Secrets */
  age.secrets = {
    pgadmin-password = {
      file = my-data.lib.getSrvSecret srvName "pgadmin-password";
      owner = config.systemd.services.pgadmin.serviceConfig.User;
      group = config.systemd.services.pgadmin.serviceConfig.User;
    };
  };

  /* Allow access only from nginx */
  systemd.services.pgadmin = {
    serviceConfig = {
      IPAddressDeny = "any";
      IPAddressAllow = [ (my-data.lib.getHostInNetwork (my-data.lib.getService "db").onHost "db").ipAddress "localhost" ];
    };
  };

}
