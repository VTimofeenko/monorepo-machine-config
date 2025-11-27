let
  serviceName = "filedump";
in
rec {
  default = [
    module
    ingress.impl
  ];
  module = ./. + "/${serviceName}.nix";

  dashboard = {
    category = "Home";
    links = [
      {
        icon = "filebrowser";
        name = "Filedump";
      }
    ];
  };

  ingress =
    let
      port = 80;
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
