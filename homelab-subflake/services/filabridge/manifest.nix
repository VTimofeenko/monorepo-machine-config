{ serviceName, ... }:
{
  module = ./filabridge.nix;

  endpoints.web = {
    port = 5150;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  # FilaBridge has no auth of its own
  sslProxyConfig = import ./non-functional/ssl.nix { inherit serviceName; };

  backups = {
    paths = [ "/var/lib/private/filabridge" ];
  };

  dashboard = {
    category = "Home";
    links = [
      {
        name = "FilaBridge";
        icon = "spoolman";
        description = "PrusaLink → Spoolman filament usage";
      }
    ];
  };

  roamNodes = [
    "a1cba4a7-c6a3-4745-8ec7-4e2a8192304a" # Filament spools
    "4b22f3ee-7128-4f9f-acff-9a2757c866b6" # 3d printing history
    "8f2a172c-779b-47f6-892e-79e52b82bcd8" # FilaBridge
    "c9665a01-b056-4c5d-a219-b8f449fd399c" # Prusa Exporter
  ];
}
