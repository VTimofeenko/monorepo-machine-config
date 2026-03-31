{ ... }:
{
  # Firewall rules for metrics are now auto-generated from endpoints.
  # This module only configures Keycloak's metrics settings.

  services.keycloak.settings = {
    metrics-enabled = true;
    http-management-scheme = "http"; # Otherwise breaks current implementation of Prometheus scrape
    event-metrics-user-enabled = true;
  };
}
