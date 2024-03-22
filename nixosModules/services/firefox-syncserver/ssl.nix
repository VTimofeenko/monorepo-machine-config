{ config, ... }:
let
  inherit (config) my-data;
  srvName = "firefox-syncserver";
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
        proxyPass =
          let
            ctCfg = config.containers.firefox-syncserver;
          in
          "http://${ctCfg.localAddress}:${
            toString (ctCfg.config.services.firefox-syncserver.settings.port + 1)
          }";
        # proxyPass = "http://${config.containers.firefox-syncserver.localAddress}:${toString config.services.firefox-syncserver.settings.port}"; # NOTE: in reality the server is inside a container. Default port is a conincidnce and should carefully be relied upon.
        # I wonder if config.container.<...> will work?
        proxyWebsockets = true;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
