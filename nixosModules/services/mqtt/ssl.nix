{ config, ... }:
let
  inherit (config) my-data;

  ownIP = (my-data.lib.getOwnHostInNetwork "lan").ipAddress;
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
    # virtualHosts.${(my-data.lib.getService srvName).fqdn} = {
    #   forceSSL = true;
    #   sslCertificate = config.age.secrets."ssl-cert".path;
    #   sslCertificateKey = config.age.secrets."ssl-key".path;
    # };

    streamConfig = ''
      server {
        listen ${ownIP}:8883 ssl; # MQTT over TLS
        ssl_certificate ${config.age.secrets.ssl-cert.path};
        ssl_certificate_key ${config.age.secrets.ssl-key.path};
        proxy_pass 127.0.0.1:1883;
      }
    '';
    # TODO: 1883 for unencrypted?
    # TODO: 443 for websocket?
    # TODO: 14567 for QUIC (if needed)?
  };
}
