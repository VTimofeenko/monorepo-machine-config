{ config, lib, ... }:
let

  inherit (lib.homelab)
    getSettings
    getSrvSecret
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
}
