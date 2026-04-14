{ ... }:
{
  module = ./mqtt.nix;

  endpoints.mqtt = {
    port = 8883;
    protocol = "tcp";
  };

  firewall = ./non-functional/firewall.nix;

  observability = {
    logging.impl = ./non-functional/logging.nix;
  };
}
