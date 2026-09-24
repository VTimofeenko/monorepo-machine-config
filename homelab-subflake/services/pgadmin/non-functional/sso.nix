{ lib, config, ... }:
let
  keycloakRealm = (lib.homelab.getServiceConfig "keycloak").realmURL;

  # pgAdmin's `settings` type only allows plain int/bool/str values one level
  # into a list/attrset, so the OAuth2 provider entry (which needs to read the
  # client secret from `$CREDENTIALS_DIRECTORY` at runtime) is built as a
  # single `_expr` value: raw Python, spliced verbatim into
  # `/etc/pgadmin/config_system.py`. This keeps the secret out of the Nix
  # store entirely - it's only ever read from the LoadCredential file at
  # pgAdmin process start.
  oauth2Config._expr = ''
    [{
        'OAUTH2_NAME': 'keycloak',
        'OAUTH2_DISPLAY_NAME': 'Keycloak',
        'OAUTH2_CLIENT_ID': 'pgadmin',
        'OAUTH2_CLIENT_SECRET': open(__import__('os').environ['CREDENTIALS_DIRECTORY'] + '/oauth2_client_secret').read().strip(),
        'OAUTH2_TOKEN_URL': '${keycloakRealm}/protocol/openid-connect/token',
        'OAUTH2_AUTHORIZATION_URL': '${keycloakRealm}/protocol/openid-connect/auth',
        'OAUTH2_API_BASE_URL': '${keycloakRealm}/',
        'OAUTH2_USERINFO_ENDPOINT': 'protocol/openid-connect/userinfo',
        'OAUTH2_SERVER_METADATA_URL': '${keycloakRealm}/.well-known/openid-configuration',
        'OAUTH2_SCOPE': 'openid email profile',
        'OAUTH2_ICON': 'fa-key',
        'OAUTH2_BUTTON_COLOR': '#3253a8',
    }]
  '';
in
{
  systemd.services.pgadmin.serviceConfig.LoadCredential = [
    "oauth2_client_secret:${config.age.secrets.pgadmin-oauth2-client-secret.path}"
  ];

  services.pgadmin.settings = {
    AUTHENTICATION_SOURCES = [
      "oauth2"
      "internal"
    ];
    OAUTH2_AUTO_CREATE_USER = true;
    OAUTH2_CONFIG = oauth2Config;
  };
}
