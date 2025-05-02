let
  serviceName = "home-assistant";
in
rec {
  default = [
    module
    ingress.impl
    backups.impl
    monitoring.impl
  ];
  module = ./home-assistant.nix;

  ingress =
    let
      port = 8123; # Taken from `server_port`
    in
    {
      impl = import ./non-functional/firewall.nix { inherit port serviceName; };
      sslProxyConfig = import ./non-functional/ssl.nix { inherit port serviceName; };
    };

  monitoring = {
    # TODO: implement here
    impl = ./non-functional/monitoring.nix;
  };
  logging = false; # TODO: implement

  backups = rec {
    enable = true;
    schedule = "daily";
    paths = [ "/var/lib/hass" ];
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
    category = "Home";
    links = [
      {
        description = "The brains of the smart home";
        icon = "home-assistant";
        name = "Home assistant";
      }
    ];
  };

  storage = false; # Stateless
}
