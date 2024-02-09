{ config, ... }:
let
  inherit (config) my-data;
  srvName = "pgadmin";

  mgmtNet = my-data.lib.getNetwork "mgmt";
in
{
  # Secrets
  age.secrets = {
    "ssl-cert" = {
      file = my-data.lib.getSrvSecret "ssl-terminator" "cert";
      owner = config.services.nginx.user;
      inherit (config.services.nginx) group;
    };
    "ssl-key" = {
      file = my-data.lib.getSrvSecret "ssl-terminator" "private-key";
      owner = config.services.nginx.user;
      inherit (config.services.nginx) group;
    };
  };

  # SSL proxy, allow only network
  # Maybe worth changing the listen address rather than use extraConfig -- this way the future "make ssl proxy"
  # function would be easier
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts.${(my-data.lib.getService srvName).fqdn} = {
      forceSSL = true;
      sslCertificate = config.age.secrets."ssl-cert".path;
      sslCertificateKey = config.age.secrets."ssl-key".path;
      extraConfig = ''
        proxy_buffering off;
      '';
      locations."/" = {
        proxyPass = "http://localhost:${toString config.services.pgadmin.port}";
        proxyWebsockets = true;
        extraConfig = ''
          allow ${mgmtNet.settings.managementNodesSubNet}.0/24;
          deny    all;
        '';
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
