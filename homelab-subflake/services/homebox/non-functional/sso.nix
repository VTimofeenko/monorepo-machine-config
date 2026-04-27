{ lib, config, ... }:
let
  keycloakRealm = (lib.homelab.getServiceConfig "keycloak").realmURL;
in
{
  services.homebox.settings = {
    HBOX_OIDC_ENABLED = "true";
    HBOX_OIDC_ISSUER_URL = keycloakRealm;
    HBOX_OIDC_CLIENT_ID = "homebox";
    HBOX_OIDC_AUTO_REDIRECT = "true";
    HBOX_OPTIONS_ALLOW_LOCAL_LOGIN = "false";
    HBOX_OPTIONS_ALLOW_REGISTRATION = "false";
  };

  # HBOX_OIDC_CLIENT_SECRET is injected via the secret file (key=value format)
  systemd.services.homebox.serviceConfig.EnvironmentFile = [
    config.age.secrets.homebox-oidc-secret.path
  ];
}
