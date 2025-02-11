{ config, lib, ... }:
let
  inherit (config) my-data;
  inherit (lib.homelab) getServiceConfig;
  inherit (getServiceConfig srvName) heatmapToken;
  srvName = "gitea";
in
{
  age.secrets."ssl-cert" = {
    file = my-data.lib.getSrvSecret "ssl-terminator" "cert";
    owner = config.services.nginx.user;
    inherit (config.services.nginx) group;
  };
  age.secrets."ssl-key" = {
    file = my-data.lib.getSrvSecret "ssl-terminator" "private-key";
    owner = config.services.nginx.user;
    inherit (config.services.nginx) group;
  };

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
        proxyPass = "http://localhost:${toString config.services.gitea.settings.server.HTTP_PORT}";
        proxyWebsockets = true;
      };
      locations."/api/v1/users/spacecadet/heatmap" = {
        proxyPass = "http://localhost:${toString config.services.gitea.settings.server.HTTP_PORT}/api/v1/users/spacecadet/heatmap";
        extraConfig = ''
          proxy_set_header Authorization "${heatmapToken}";
        '';
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
