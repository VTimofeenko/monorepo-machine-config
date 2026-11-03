{ ... }:
{
  module = ./linkwarden.nix;

  endpoints.web = {
    port = 3000;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  backups.paths = [ "/var/lib/linkwarden" ];

  database = {
    create = true;
    impl = ./non-functional/database.nix;
  };

  dashboard = {
    category = "Home";
    links = [
      {
        name = "Linkwarden";
        icon = "linkwarden";
        description = "Collaborative bookmark manager";
      }
    ];
  };

  roamNodes = [ "d4a36e8b-91e2-45f0-b30d-7b33273c3a70" ];

  observability.logging.units = [
    "linkwarden.service"
    "linkwarden-worker.service"
  ];
}
