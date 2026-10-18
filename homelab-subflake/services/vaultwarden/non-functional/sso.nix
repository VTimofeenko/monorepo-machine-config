{ lib, ... }:
{
  # `SSO_CLIENT_SECRET` comes from the `vaultwarden-env` secret, see ./database.nix
  services.vaultwarden.config = {
    SSO_ENABLED = true;
    SSO_AUTHORITY = (lib.homelab.getServiceConfig "keycloak").realmURL;
    SSO_CLIENT_ID = "vaultwarden";
    SSO_SCOPES = "email profile";
  };
}
