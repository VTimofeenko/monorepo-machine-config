{ lib, ... }:
{
  imports = [ ./non-functional/sso.nix ];

  services.vaultwarden = {
    enable = true;
    domain = lib.homelab.getServiceFqdn "vaultwarden";
    config.SIGNUPS_ALLOWED = false;
  };
}
