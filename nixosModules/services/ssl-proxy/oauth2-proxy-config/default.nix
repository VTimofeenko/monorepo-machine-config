/**
  Sets up `oauth2-proxy` for SSO to certain domains
*/
{ lib, config, ... }:
let
  srvName = "oauth2-proxy";
  secretName = "${srvName}-client-secret";
  domainPart = lib.homelab.getSettings.publicDomainName;
in
{
  services.oauth2-proxy = {
    enable = true;
    nginx.domain = lib.homelab.getServiceFqdn srvName;
    provider = "keycloak-oidc";

    clientID = "oauth2-proxy";
    keyFile = config.age.secrets.${secretName}.path;

    setXauthrequest = true;

    cookie = {
      secret = (lib.homelab.getServiceConfig srvName).cookie;
      secure = true;
      domain = ".${domainPart}";
      httpOnly = true;
    };

    extraConfig = {
      "oidc-issuer-url" = "https://${"keycloak" |> lib.homelab.getServiceFqdn}/realms/master";

      "set-xauthrequest" = "true";
      "whitelist-domain" = ".${domainPart}";

      # Optional: If you want to verify email domains
      "email-domain" = "*";

      # Optional: If your upstream requires the OIDC access token
      # "pass-access-token" = "true";

      session-cookie-minimal = true;
      # Reducing the scope helps with "headers" too large
      scope = [
        "email"
        "openid"
      ];
    };

    nginx.virtualHosts =
      [
        "healthchecks"
      ]
      |> map (it: {
        name = lib.homelab.getServiceFqdn it;
        value = { };
      })
      |> lib.listToAttrs;
  };

  age.secrets.${secretName}.owner = "oauth2-proxy";

  imports = lib.localLib.mkImportsFromDir ./per-service;

  services.nginx.virtualHosts.${lib.homelab.getServiceFqdn srvName} = {
    forceSSL = true;
    inherit (config.services.homelab.ssl-proxy) listenAddresses;
    sslCertificate = config.age.secrets."ssl-cert".path;
    sslCertificateKey = config.age.secrets."ssl-key".path;
  };

  services.nginx.virtualHosts."healthchecks.srv.vtimofeenko.com" = {

            # locations."@redirectToAuth2ProxyLogin" = lib.mkForce {
            #   return = "307 https://healthchecks.srv.vtimofeenko.com/oauth2/start?rd=$scheme://$host$request_uri";
            #   extraConfig = ''
            #     auth_request off;
            #   '';
            # };

  };
}
