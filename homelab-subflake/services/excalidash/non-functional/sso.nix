{ lib, config, ... }:
let
  keycloakRealm = (lib.homelab.getServiceConfig "keycloak").realmURL;
  fqdn = "excalidash" |> lib.homelab.getServiceFqdn;
in
{
  services.excalidash = {
    # Keeps local-password login as a fallback alongside OIDC. Switch to
    # `"oidc_enforced"` to disable local auth entirely once SSO is confirmed
    # working.
    authMode = "hybrid";

    environment = {
      OIDC_PROVIDER_NAME = "Keycloak";
      OIDC_ISSUER_URL = keycloakRealm;
      OIDC_CLIENT_ID = "excalidash";
      OIDC_REDIRECT_URI = "https://${fqdn}/api/auth/oidc/callback";
      OIDC_SCOPES = "openid profile email";
    };

    secretFiles.OIDC_CLIENT_SECRET = config.age.secrets.excalidash-oidc-client-secret.path;
  };
}
