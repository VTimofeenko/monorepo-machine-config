rec {
  default = [
    module
    ingress.internal
  ];
  module = ./service.nix;
  ingress.internal = ./firewall.nix;

  monitoring = false; # TODO: implement
  logging = false; # TODO: implement
  srvLib = import ./srv-lib.nix;
  # Stateless service
  backups = false;
  storage = false;
}
