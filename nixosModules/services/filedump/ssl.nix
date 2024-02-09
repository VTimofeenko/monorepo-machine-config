{ config, ... }:
let
  inherit (config) my-data;
  srvName = "filedump";
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
        extraConfig = ''
          autoindex on;
        '';
        root = config.services.myFiledump.dir;
      };
      locations."~ /${config.services.myFiledump.dashboard-icons}/png" = {
        extraConfig = ''
          error_page 404 /${config.services.myFiledump.dashboard-icons}/png/nginx.png;
        '';
        root = config.services.myFiledump.dir;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
