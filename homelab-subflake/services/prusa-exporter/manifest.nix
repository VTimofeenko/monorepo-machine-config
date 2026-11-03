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

  observability = {
    metrics = {
      main = {
        endpoint = "main-metrics";
        path = "/metrics/prusalink";
      };
      udp = {
        endpoint = "main-metrics";
        path = "/metrics/udp";
      };
    };
    alerts.prometheusImpl = ./non-functional/alerts.nix;
    logging.units = [ "prometheus-prusa-exporter.service" ];
    dashboards = {
      enable = true;
      mod = ./dashboard.nix;
    };
  };
  # No backups – stateless exporter
}
