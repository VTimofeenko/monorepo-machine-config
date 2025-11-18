rec {
  default = [
    module
    ingress.firewall
    observability.metrics.impl
  ];
  module = ./kea.nix;
  ingress.firewall = ./firewall.nix;

  storage = false; # Stateless
  backups = false; # Stateless
  observability = {
    enable = true;
    metrics = rec {
      enable = true;
      impl = if enable then ./non-functional/metrics.nix else { };
      path = "/";
      port = 9547;
    };
  };
  logging = false; # TODO
}
