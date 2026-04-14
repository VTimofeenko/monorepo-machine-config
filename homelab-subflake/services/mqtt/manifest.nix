{ ... }:
{
  module = ./mqtt.nix;

  endpoints.mqtt = {
    port = 8883;
    protocol = "tcp";
  };

  firewall = ./non-functional/firewall.nix;

  sslProxyConfig = import ./non-functional/ssl.nix;

  observability = {
    logging.impl = ./non-functional/logging.nix;
  };
}
