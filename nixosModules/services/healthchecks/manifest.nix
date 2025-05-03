let
  serviceName = "healthchecks";
in
rec {
  default = [
    module
    ingress.internal
  ];
  module = ./. + "${serviceName}.nix";
  ingress =
    let
      port = 8000;
    in
    {
      impl = import ./non-functional/firewall.nix { inherit port; };
      sslProxyConfig = import ./non-functional/ssl.nix { inherit port serviceName; };
    };

  monitoring = false; # TODO: implement
  logging = false; # TODO: implement
  # Stateless service
  backups = false;
  storage = false;

  dashboard = {
    category = "Admin";
    links = [
      {
        description = "Periodic ping reporting (backups, network check, etc.)";
        icon = "healthchecks";
        name = "Healthchecks";
      }
    ];
  };
}
