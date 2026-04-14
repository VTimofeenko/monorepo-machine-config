{ ... }:
{
  module = ./mqtt.nix;

  endpoints.mqtt = {
    port = 8883;
    protocol = "tcp";
  };

  sslProxyConfig = import ./non-functional/ssl.nix;

  observability = {
    logging.impl = ./non-functional/logging.nix;
  };
}
