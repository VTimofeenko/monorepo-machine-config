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

  documentation = ./README.md;
}
