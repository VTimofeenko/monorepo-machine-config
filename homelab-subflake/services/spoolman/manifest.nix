{ serviceName, ... }:
{
  module = ./spoolman.nix;

  endpoints.web = {
    port = 7912;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  # Spoolman has no auth of its own
  sslProxyConfig = import ./non-functional/ssl.nix { inherit serviceName; };

  observability = {
    metrics.main.impl = ./non-functional/observability/metrics/impl.nix;
    alerts.prometheusImpl = ./non-functional/alerts.nix;
  };

  database = {
    create = true;
    impl = ./non-functional/database.nix;
  };

  dashboard = {
    category = "Home";
    links = [
      {
        name = "Spoolman";
        icon = "spoolman";
        description = "3D printing filament inventory";
      }
    ];
  };

  roamNodes = [
    "a1cba4a7-c6a3-4745-8ec7-4e2a8192304a" # Filament spools
    "4b22f3ee-7128-4f9f-acff-9a2757c866b6" # 3d printing history
    "998debdd-f478-4c15-b0fc-07f8c8d03d54" # Spoolman
  ];
}
