{ lib, ... }:
{
  module = ./mqtt.nix;

  srvLib = import ./srv-lib.nix { inherit lib; };

  endpoints.mqtt = {
    port = 8883;
    protocol = "tcp";
  };

  firewall = ./non-functional/firewall.nix;

  observability = {
    logging = {
      impl = ./non-functional/logging.nix;
      units = [ "mosquitto.service" ];
    };
  };
}
