{ config, ... }:
let
  inherit (config) my-data;
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
    virtualHosts.${(my-data.lib.getService "tt-rss").fqdn} = {
      forceSSL = true;
      sslCertificate = config.age.secrets."ssl-cert".path;
      sslCertificateKey = config.age.secrets."ssl-key".path;
      extraConfig = ''
        proxy_buffering off;
      '';
      # NOTE: set up by tt-rss NixOS module
      # locations."/" = {
      #   proxyPass = "http://localhost:8334";
      #   proxyWebsockets = true;
      # };
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
