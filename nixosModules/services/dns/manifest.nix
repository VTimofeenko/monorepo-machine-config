/**
  Manifest for the recursive DNS service
*/
rec {
  default = [
    module
  ]
  ++ (ingress |> builtins.attrValues)
  ++ observability.impl;
  module = ./unbound.nix;

  ingress = {
    firewall = ./non-functional/firewall.nix;
    acl = ./non-functional/acl.nix;
  };

  observability = rec {
    enable = true;
    impl = [
      metrics.impl
      logging.impl
    ];
    metrics = rec {
      enable = true;
      impl = if enable then ./non-functional/metrics.nix else { };
      port = 9167;
    };
    alerts = {
      enable = true;
      grafanaImpl = import ./non-functional/alerts.nix;
    };
    logging = {
      impl = ./non-functional/logging.nix;
    };
  };

  backups = false; # Stateless
  storage = false; # Stateless
}
