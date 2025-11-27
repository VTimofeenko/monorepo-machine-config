let
  serviceName = "home-dashboard";
in
rec {
  default = [
    module
    ingress.impl
  ];
  module = ./. + "/${serviceName}.nix";

  # `dashboard = false`; # No point in adding dashboard to itself.

  ingress =
    let
      port = 8082; # Taken from `listenPort`
    in
    {
      impl = import ./non-functional/firewall.nix { inherit port serviceName; };
      sslProxyConfig = import ./non-functional/ssl.nix { inherit port serviceName; };
    };

  observability = {
    enable = true;
    alerts = rec {
      enable = true;
      grafanaImpl = if enable then import ./non-functional/alerts.nix { inherit serviceName; } else { };
    };
  };

  backups = false; # Stateless
  storage = false; # Stateless
}
