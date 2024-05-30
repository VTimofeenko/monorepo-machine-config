{ config, lib, ... }:
let

  inherit (lib.homelab)
    getSettings
    getService
    getSrvSecret
    getHostInNetwork
    ;
  srvName = "pgadmin";
in
{
  # Service config
  services.pgadmin = {
    enable = true;
    initialEmail = "pgadmin@${getSettings.publicDomainName}";
    initialPasswordFile = "${config.age.secrets.pgadmin-password.path}";
    settings = {
      UPGRADE_CHECK_ENABLED = false;
    };
  };

  # Secrets
  age.secrets = {
    pgadmin-password = {
      file = getSrvSecret srvName "pgadmin-password";
      owner = config.systemd.services.pgadmin.serviceConfig.User;
      group = config.systemd.services.pgadmin.serviceConfig.User;
    };
  };

  # Allow access only from nginx
  systemd.services.pgadmin = {
    serviceConfig = {
      IPAddressDeny = "any";
      IPAddressAllow = [
        (getHostInNetwork (getService "db").onHost "db").ipAddress
        "localhost"
      ];
    };
  };
}
