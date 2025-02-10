rec {
  default = [
    module
    ingress.firewall
    monitoring.impl
  ];
  module = ./kea.nix;
  ingress.firewall = ./firewall.nix;

  storage = false; # Stateless
  backups = false; # Stateless
  monitoring.impl = ./monitoring.nix;
  logging = false; # TODO
}
