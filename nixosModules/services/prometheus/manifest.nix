let
  serviceName = "prometheus";
in
rec {
  default = [
    module
    ingress.impl
    backups.impl
    storage.impl
  ];

  module = ./service.nix;

  ingress =
    let
      port = 9090;
    in
    {
      impl = ./non-functional/firewall.nix;
      sslProxyConfig = ./non-functional/ssl.nix;
    }
    |> builtins.mapAttrs (_: v: import v { inherit port serviceName; });

  observability = {
    enable = true;
    metrics = {
      enable = true;
      path = "/metrics";
    };
    logging = {
      enable = false;
      systemdUnit = "prometheus.service";
    };
    alerts = {
      enable = true;
      grafanaImpl = import ./non-functional/alerts.nix { inherit serviceName; };
    };
  };

  dashboard = {
    category = "Admin";
    links = [
      {
        description = "Scrapes and stores metrics for monitoring";
        icon = "prometheus";
        name = "Prometheus";
      }
    ];
  };

  # Backups disabled, TODO: data to be replicated
  backups = rec {
    enable = false;
    impl = if enable then { lib, ... }: lib.localLib.mkBkp { inherit serviceName; } else { };
  };

  storage.impl = ./non-functional/storage.nix;

  srvLib = import ./srv-lib.nix;
}
