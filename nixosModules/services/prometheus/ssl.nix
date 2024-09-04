{ config, lib, ... }:
let
  inherit (lib.homelab)
    getServiceSecret
    getServiceFqdn
    getSettings
    getServiceConfig
    ;
  fqdn = getServiceFqdn srvName;
  srvName = "prometheus";
  proxyUrl = "http://${config.services.${srvName}.listenAddress}:${
    toString config.services.${srvName}.port
  }";
in
{
  services.oauth2-proxy = {
    enable = false;
    httpAddress = "http://127.0.0.1:4180";

    cookie = {
      secure = true;
      domain = fqdn;
    };

    upstream = [
      (
        assert config.services.prometheus.enable;
        proxyUrl
      )
    ];

    extraConfig = {
      whitelist-domain = [
        fqdn
        getSettings.publicDomainName
      ];
      session-cookie-minimal = true;
      # Reducing the scope helps with "headers" too large
      scope = [ "openid" ];

      # The following two options are critical -- they allow grafana's 'forward OAuth Identity' to work
      # At least for me :)
      skip-jwt-bearer-tokens = true;
      extra-jwt-issuers = [ "${(getServiceConfig "keycloak").realmURL}=master-realm" ];
    };

    keyFile = config.age.secrets.oauth2-prometheus-client-secret.path;
    provider = "keycloak-oidc";

    nginx.domain = fqdn;
    nginx.virtualHosts.${fqdn}.allowed_email_domains = [ getSettings.domain ];
    email.domains = [ getSettings.domain ];
    oidcIssuerUrl = (getServiceConfig "keycloak").realmURL;

  };

  # Nginx config
  # Without it -- nothing is really served
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts.${fqdn} = {
      forceSSL = true;
      locations."/" = {
        proxyPass = proxyUrl;
        proxyWebsockets = true;
      };
      sslCertificate = config.age.secrets."ssl-cert".path;
      sslCertificateKey = config.age.secrets."ssl-key".path;
    };
  };

  # Secrets
  age.secrets = {
    # oauth2-prometheus-client-secret = {
    #   file = getServiceSecret srvName "oauth2-prometheus-client-secret";
    #   owner = config.users.users.oauth2-proxy.name;
    # };

    "ssl-cert" = {
      file = getServiceSecret "ssl-terminator" "cert";
      owner = config.services.nginx.user;
      inherit (config.services.nginx) group;
    };
    "ssl-key" = {
      file = getServiceSecret "ssl-terminator" "private-key";
      owner = config.services.nginx.user;
      inherit (config.services.nginx) group;
    };
  };

}
