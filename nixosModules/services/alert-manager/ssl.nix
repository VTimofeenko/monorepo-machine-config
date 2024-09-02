{ config, lib, ... }:
let
  inherit (lib.homelab)
    getServiceSecret
    getServiceFqdn
    getSettings
    getServiceConfig
    ;
  fqdn = getServiceFqdn srvName;
  srvName = "alert-manager";
  proxyUrl = "http://${config.services.prometheus.alertmanager.listenAddress}:${toString config.services.prometheus.alertmanager.port}";
in
{
  services.oauth2-proxy = {
    enable = true;
    httpAddress = "http://127.0.0.1:4180";

    cookie = {
      secure = true;
      domain = getSettings.publicDomainName;
    };

    upstream = [
      (
        assert config.services.prometheus.alertmanager.enable;
        (proxyUrl + "/${srvName}")
      )
    ];

    # extraConfig = {
    #   whitelist-domain = [
    #     fqdn
    #     getSettings.publicDomainName
    #   ];
    #   session-cookie-minimal = true;
    #   # Reducing the scope helps with "headers" too large
    #   scope = [ "openid" ];

    #   # The following two options are critical -- they allow grafana's 'forward OAuth Identity' to work
    #   # At least for me :)
    #   skip-jwt-bearer-tokens = true;
    #   extra-jwt-issuers = [ "${(getServiceConfig "keycloak").realmURL}=master-realm" ];
    # };

    # keyFile = config.age.secrets.oauth2-alert-manager-client-secret;
    provider = "keycloak-oidc";

    nginx.domain = getSettings.publicDomainName;
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
    oauth2-alert-manager-client-secret = {
      file = getServiceSecret srvName "oauth2-alert-manager-client-secret";
      owner = config.users.users.oauth2-proxy.name;
    };

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
