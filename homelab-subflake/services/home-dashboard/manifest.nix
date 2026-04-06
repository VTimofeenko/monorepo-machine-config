{ serviceName, ... }:
{
  module = ./home-dashboard.nix;

  endpoints.web = {
    port = 8082;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  observability = {
    alerts.grafanaImpl = import ./non-functional/alerts.nix { inherit serviceName; };
  };

  # No dashboard entry for the dashboard itself.
}
