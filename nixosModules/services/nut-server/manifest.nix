/**
  Manifest for the NUT server.
*/
rec {
  default = [
    module
  ]
  ++ (ingress |> builtins.attrValues)
  ++ observability.impl;

  module = ./nut.nix;

  ingress.firewall = ./non-functional/firewall.nix;

  observability = rec {
    enable = true;
    impl = [
      metrics.impl
    ];
    metrics = rec {
      enable = true;
      impl = if enable then ./non-functional/metrics.nix else { };
      port = 9199;
      path = "/ups_metrics";
    };

    logging.enable = false;
  };

  backups = false; # Stateless
  storage = false; # Stateless
}
