let
  serviceName = "ssl-proxy";
in
rec {
  default = [
    module
    ingress.internal
  ]
  ++ observability.impl;
  observability = rec {
    enable = true;
    impl =
      if enable then
        [
          metrics.impl
          probes.impl
        ]
      else
        [ ];
    metrics = rec {
      enable = true;
      path = "/metrics";
      port = 9598;
      impl = if enable then import ./non-functional/observability/metrics.nix { inherit port; } else { };
    };
    probes = rec {
      enable = true;
      port = 9219;
      impl = if enable then import ./non-functional/probes { inherit port; } else { };
      prometheusImpl =
        if enable then import ./non-functional/probes/prometheus.nix { inherit port serviceName; } else { };
    };
    alerts = {
      enable = true;
      grafanaImpl = {
        Alert = [
          {
            title = "Scrape is down";
            query = "up{job=\"ssl-proxy-srv-scrape\"}";
          }
        ];
      };
    };
  };
  module = ./service.nix;
  ingress.internal = ./firewall.nix;

  srvLib = import ./srv-lib.nix;
  # Stateless service
  backups = false;
  storage = false;
}
