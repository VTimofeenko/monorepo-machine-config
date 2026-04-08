{ lib, ... }:
{
  module = ./service.nix;

  # Network endpoints for observability
  endpoints = {
    metrics = {
      port = 9598;
      protocol = "tcp";
      path = "/metrics";
    };
    probe = {
      port = 9219;
      protocol = "tcp";
    };
  };

  # Custom firewall configuration
  firewall = ./firewall.nix;

  observability = {
    metrics.main.impl = ./non-functional/observability/metrics.nix;
    probes = {
      enable = true;
      impl = ./non-functional/probes;
      prometheusImpl = ./non-functional/probes/prometheus.nix;
    };
    alerts.prometheusImpl = ./non-functional/alerts.nix;
  };

  srvLib = import ./srv-lib.nix { inherit lib; };

  # Stateless service - no backups or storage needed
}
