{ serviceName, ... }:
{
  module = ./service.nix;

  endpoints.web = {
    port = 9090;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  observability = {
    metrics.main.path = "/metrics";
    alerts.grafanaImpl = import ./non-functional/alerts.nix { inherit serviceName; };
  };

  storage.impl = ./non-functional/storage.nix;

  dashboard = {
    category = "Admin";
    links = [
      {
        description = "Scrapes and stores metrics for monitoring";
        icon = "prometheus";
        name = "Prometheus";
      }
    ];
  };

  srvLib = import ./srv-lib.nix;

  # Backups disabled - data to be replicated
}
