{ serviceName, ... }:
{
  module = ./ntfy-sh.nix;

  endpoints.web = {
    port = 8004;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  observability = { }; # TODO: implement proper metrics here

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
