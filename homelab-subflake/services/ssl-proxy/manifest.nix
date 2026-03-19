{ lib, serviceName, ... }:
{
  module = ./service.nix;

  # Network endpoints for observability
  endpoints = {
    metrics = {
      port = 9598;
      protocol = "tcp";
      path = "/metrics";
    };
    probes = {
      port = 9219;
      protocol = "tcp";
    };
  };

  # Custom firewall configuration
  firewall = ./firewall.nix;

  observability = {
    metrics.main.impl = import ./non-functional/observability/metrics.nix { port = 9598; };
    probes.impl = import ./non-functional/probes { port = 9219; };
    alerts.grafanaImpl = import ./non-functional/alerts.nix { inherit serviceName; };
  };

  srvLib = import ./srv-lib.nix;

  # Stateless service - no backups or storage needed
}
