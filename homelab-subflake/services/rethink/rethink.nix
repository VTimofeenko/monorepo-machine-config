/**
  rethink: local LG ThinQ cloud. The appliances stay factory-paired to
  `*.lgthinq.com`; their DNS view (`dns` service, `functional/thinq-view.nix`)
  resolves those names to this host's LAN IP.

  The appliances only trust the eMudhra chain they were fed, which rethink can't
  serve itself (its CA is RSA only and it sends no intermediates). So nginx
  terminates TLS with that chain and passes plaintext to rethink:

    lan:443  --TLS--> nginx --> rethink http_port
    lan:8883 --TLS--> nginx --> rethink mqtt_port (its own broker)

  Appliance data is republished to the `mqtt` service, where Home Assistant
  picks it up.
*/
{ config, lib, ... }:
let
  lanIP = lib.homelab.getOwnIpInNetwork "lan";

  httpPort = 8580;
  mqttPort = 1884;

  tlsCommon = ''
    ssl_certificate_key ${config.age.secrets.rethink-emudhra-key.path};
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_ciphers ALL:@SECLEVEL=0;
  '';
in
{
  services.rethink = {
    enable = true;
    settings = {
      hostname = "aic-common.lgthinq.com";

      # TLS is nginx's; rethink binds plaintext only and advertises the LG names
      http_port = {
        bind = httpPort;
        address = "127.0.0.1";
      };
      https_port.advertise = "https://aic-common.lgthinq.com:443";
      mqtt_port = {
        bind = mqttPort;
        address = "127.0.0.1";
      };
      mqtts_port.advertise = "ssl://common.iot.aic.lgthinq.com:8883";

      # Served at /route/certificate?name=aws-iot. The appliances validate :8883
      # against this RSA-2048 root CA.
      custom_root_cert_file = "/run/credentials/rethink.service/root.pem";

      # ThinQ2 only
      thinq1_https_port = { };
      thinq1_port = { };

      homeassistant = {
        mqtt_url = "mqtts://${lib.homelab.getServiceFqdn "mqtt"}:${
          (lib.homelab.getManifest "mqtt").endpoints.mqtt.port |> toString
        }";
        # No upstream defaults: unset, topics become `undefined/...`
        discovery_prefix = "homeassistant";
        rethink_prefix = "rethink";
      };
    };
  };

  systemd.services.rethink.serviceConfig.LoadCredential = [
    "root.pem:${config.age.secrets.rethink-emudhra-root.path}"
  ];

  age.secrets = {
    rethink-emudhra-chain = {
      owner = config.services.nginx.user;
      inherit (config.services.nginx) group;
    };
    rethink-emudhra-mqtt-cert = {
      owner = config.services.nginx.user;
      inherit (config.services.nginx) group;
    };
    rethink-emudhra-key = {
      owner = config.services.nginx.user;
      inherit (config.services.nginx) group;
    };
  };

  services.nginx = {
    enable = true;
    streamConfig = ''
      server {
        listen ${lanIP}:443 ssl; # ThinQ HTTPS API (validates against factory emSign Root)
        ssl_certificate ${config.age.secrets.rethink-emudhra-chain.path};
        ${tlsCommon}
        proxy_pass 127.0.0.1:${toString httpPort};
      }
      server {
        listen ${lanIP}:8883 ssl; # ThinQ MQTTS (validates against root.pem from /route/certificate)
        ssl_certificate ${config.age.secrets.rethink-emudhra-mqtt-cert.path};
        ${tlsCommon}
        proxy_pass 127.0.0.1:${toString mqttPort};
      }
    '';
  };
}
