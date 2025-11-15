rec {
  default = [
    module
    ingress.internal
  ]
  ++ observability.impl;
  observability = rec {
    enable = true;
    impl = if enable then [ metrics.impl ] else [ ];
    metrics = rec {
      enable = true;
      path = "/metrics";
      port = 9598;
      impl = if enable then import ./non-functional/observability/metrics.nix { inherit port; } else { };
    };
  };
  module = ./service.nix;
  ingress.internal = ./firewall.nix;

  srvLib = import ./srv-lib.nix;
  # Stateless service
  backups = false;
  storage = false;
}
