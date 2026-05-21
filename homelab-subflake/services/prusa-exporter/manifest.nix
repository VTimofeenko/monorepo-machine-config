{ ... }:
{
  module = ./service.nix;

  endpoints = {
    # Endpoint for gathering PrusaLink metrics.
    main-metrics = {
      port = 10009;
      protocol = "tcp";
    };
  };

  observability.metrics = {
    main = {
      endpoint = "main-metrics";
      path = "/metrics/prusalink";
    };
    udp = {
      endpoint = "main-metrics";
      path = "/metrics/udp";
    };
  };

  # No backups – stateless exporter
  # No dashboard – infrastructure metrics only
}
