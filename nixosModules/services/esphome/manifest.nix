let
  serviceName = "esphome";
in
rec {
  default = [
    module
    ingress.impl
  ];
  module = ./. + "/${serviceName}.nix";

  ingress =
    let
      port = 6052; # taken from services.esphome.port
    in
    {
      impl = import ./non-functional/firewall.nix { inherit port serviceName; };
      sslProxyConfig = import ./non-functional/ssl.nix { inherit port serviceName; };
    };

  monitoring = false; # TODO: implement
  logging = false; # TODO: implement

  backups = rec { # TODO: implement
    enable = true;
    schedule = "daily";
    paths = [  ];
    impl =
      if enable then
        { lib, ... }:
        lib.localLib.mkBkp {
          inherit paths serviceName;
        }
      else
        { };
  };

  dashboard = {
    category = "Dev";
    links = [
      {
        description = "Firmware manager for all the random esp32s";
        icon = "esphome";
        name = "ESPhome";
      }
    ];
  };

  storage = false; # Stateless
}
