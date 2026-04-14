{ config, lib, ... }:
let
  ownIP = lib.homelab.getOwnIpInNetwork "lan";
in
{
  age.secrets.ssl-cert = {
    owner = config.services.nginx.user;
    inherit (config.services.nginx) group;
  };
  age.secrets.ssl-key = {
    owner = config.services.nginx.user;
    inherit (config.services.nginx) group;
  };

  services.nginx = {
    enable = true;
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
