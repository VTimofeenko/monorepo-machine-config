{
  lib,
  config,
  pkgs,
  ...
}:
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
    HBOX_OPTIONS_TRUST_PROXY = "true";
  };

  # HBOX_OIDC_CLIENT_SECRET is injected via the secret file (key=value format)
  systemd.services.homebox.serviceConfig.EnvironmentFile = [
    config.age.secrets.homebox-oidc-secret.path
  ];

  /**
    Homebox runs OIDC discovery only at startup (~7.5s of retries), then keeps
    running without a provider: every login returns 500 "OIDC provider not
    available" until restarted. Hold the start until Keycloak answers.

    FIXME: drop once upstream re-initializes the provider lazily
    https://github.com/sysadminsmedia/homebox/issues/1471
  */
  systemd.services.homebox.serviceConfig = {
    ExecStartPre = [
      "${lib.getExe pkgs.curl} --fail --silent --show-error --output /dev/null --max-time 10 --retry 1000 --retry-delay 5 --retry-all-errors --retry-max-time 240 ${keycloakRealm}/.well-known/openid-configuration"
    ];
    TimeoutStartSec = "5min";
  };
}
