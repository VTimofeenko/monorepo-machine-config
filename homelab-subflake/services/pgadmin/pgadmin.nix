{ config, lib, ... }:
let
  inherit (lib.homelab) getSettings ;
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
}
