{ serviceName, ... }:
{
  module = ./ntfy-sh.nix;
  endpoints = rec {

    web = {
      port = 8004;
      protocol = "https";
    };

    metrics = {
      inherit (web) port;
      protocol = "tcp";
      path = "/metrics";
    };
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  observability = {
    metrics.main.impl = ./non-functional/metrics.nix;
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
