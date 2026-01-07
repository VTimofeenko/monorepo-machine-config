let
  serviceName = "cyberchef";
in
rec {
  default = [
    module
    ingress.impl
  ];
  module = ./. + "/${serviceName}.nix";

  dashboard = {
    category = "Development";
    links = [
      {
        icon = "cyberchef";
        name = "Cyberchef";
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

  observability.enable = false;
  backups = false; # Stateless
  storage = false; # Stateless
}
