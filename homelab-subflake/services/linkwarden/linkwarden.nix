{ lib, config, ... }:
{
  services.linkwarden = {
    enable = true;

    environment.NEXTAUTH_URL = "https://${lib.homelab.getServiceFqdn "linkwarden"}/api/v1/auth";

    secretFiles.NEXTAUTH_SECRET = config.age.secrets.linkwarden-nextauth-secret.path;

    environment = {
      NEXT_PUBLIC_KEYCLOAK_ENABLED = "true";
      KEYCLOAK_ISSUER = (lib.homelab.getServiceConfig "keycloak").realmURL;
      KEYCLOAK_CLIENT_ID = "linkwarden";
    };

    secretFiles.KEYCLOAK_CLIENT_SECRET = config.age.secrets.linkwarden-keycloak-secret.path;
  };
}
