{ serviceName, ... }:
{
  module = ./reopenscad.nix;

  endpoints.web = {
    port = 5180;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  # No auth of its own: a design's URL is its only key
  sslProxyConfig = import ./non-functional/ssl.nix { inherit serviceName; };

  # Designs, revisions and uploaded STLs all live in Postgres
  database = {
    create = true;
    impl = ./non-functional/database.nix;
  };

  dashboard = {
    category = "Dev";
    links = [
      {
        name = "ReOpenSCAD";
        icon = "auto-cad";
        description = "OpenSCAD workbench in the browser";
      }
    ];
  };

  roamNodes = [
    "4b22f3ee-7128-4f9f-acff-9a2757c866b6" # 3d printing history
  ];
}
