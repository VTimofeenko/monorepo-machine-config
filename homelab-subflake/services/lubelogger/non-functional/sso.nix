{ lib, ... }:
let
  keycloakRealm = (lib.homelab.getServiceConfig "keycloak").realmURL;
in
{
  services.lubelogger = {
    enable = true;
    settings = {
      OpenIDConfig__Name = "Keycloak";
      OpenIDConfig__ClientId = "lubelogger";
      OpenIDConfig__AuthURL = "${keycloakRealm}/protocol/openid-connect/auth";
      OpenIDConfig__TokenURL = "${keycloakRealm}/protocol/openid-connect/token";
      EnableAuth = "true";
      OpenIDConfig__RedirectURL = "https://${lib.homelab.getServiceFqdn "lubelogger"}/Login/RemoteAuth";
      OpenIDConfig__DisableRegularLogin = "true"; # optional: skip the login form
      OpenIDConfig__LogOutURL = "${(lib.homelab.getServiceConfig "keycloak").realmURL}/protocol/openid-connect/logout";
      OpenIDConfig__AutoGenerateTokens = "true";
      EnableRootUserOIDC = "true";
      UserNameHash = "280e6555c7b9263d3baa003e2c7433d3ca28741bffc175082709a2e4450f3377";
    };
  };
}
