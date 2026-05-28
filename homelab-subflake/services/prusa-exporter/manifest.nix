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

  # Grafana dashboard (HTTP/PrusaLink metrics only – no UDP exporter required)
  observability.dashboards = {
    enable = true;
    mod = ./dashboard.nix;
  };

  observability.alerts.prometheusImpl = ./non-functional/alerts.nix;
}
