/**
  Manifest for the recursive DNS service
*/
rec {
  default = [
    module
    monitoring.impl
    logging.impl
  ] ++ (ingress |> builtins.attrValues);
  module = ./unbound.nix;

  monitoring = {
    impl = ./non-functional/monitoring.nix;
  };

  logging = {
    impl = ./non-functional/logging.nix;
  };

  ingress = {
    firewall = ./non-functional/firewall.nix;
    acl = ./non-functional/acl.nix;
  };

  backups = false; # Stateless
  storage = false; # Stateless
}

