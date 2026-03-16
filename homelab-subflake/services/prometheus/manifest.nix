{ lib, serviceName, ... }:
{
  module = ./service.nix;

  endpoints.web = {
    port = 9090;
    protocol = "https";
  };

  firewall = import ./non-functional/firewall.nix { port = 9090; serviceName = "prometheus"; };

  sslProxyConfig = import ./non-functional/ssl.nix { port = 9090; serviceName = "prometheus"; };

  observability = {
    metrics.path = "/metrics";
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
