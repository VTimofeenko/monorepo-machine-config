{ serviceName, ... }:
{
  module = ./ntfy-sh.nix;

  endpoints.web = {
    port = 8004;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  observability = {
    alerts.grafanaImpl = import ./non-functional/alerts.nix { inherit serviceName; };
  };

  # Backups disabled — no persistent state to back up
  # backups = { ... };

  dashboard = {
    category = "Dev";
    links = [
      {
        description = "Local notifications";
        icon = "ntfy";
        name = "Ntfy";
      }
    ];
  };
}
