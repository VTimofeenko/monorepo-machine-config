let
  serviceName = "home-assistant";
in
rec {
  default = [
    module
    ingress.impl
    backups.impl
    observability.metrics.impl
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

  observability = {
    enable = true;
    metrics = rec {
      enable = true;
      impl = if enable then import ./non-functional/metrics.nix else { };
      path = "/api/prometheus";
    };
    alerts = rec {
      enable = true;
      grafanaImpl = if enable then import ./non-functional/alerts.nix { inherit serviceName; } else { };
    };
  };

  storage = false; # Stateless
}
