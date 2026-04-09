/**
  Manifest for the NUT (Network UPS Tools) server.

  Provides UPS monitoring and power management over the network.
*/
{ serviceName, ... }:
{
  module = ./nut.nix;

  endpoints = {
    nut = {
      port = 3493;  # Standard NUT server protocol port
      protocol = "tcp";
    };
    metrics = {
      port = 9199;  # Prometheus exporter port
      protocol = "tcp";
    };
  };

  # Custom firewall: configures client IP allowlist and listen address
  firewall = ./non-functional/firewall.nix;

  observability = {
    # NUT exporter provides UPS metrics on dedicated port
    metrics.main = {
      impl = ./non-functional/metrics.nix;
      path = "/ups_metrics";
      endpoint = "metrics";
    };

    alerts.prometheusImpl = ./non-functional/alerts.nix;
  };

  # Stateless service - no backups or storage needed
}
