{ ... }:
{
  module = ./lubelogger.nix;

  endpoints.web = {
    port = 5000;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  database = {
    create = true;
    impl = ./non-functional/database.nix;
  };

  storage.impl = ./non-functional/storage.nix;

  backups = {
    paths = [ "/var/lib/lubelogger" ];
  };

  dashboard = {
    category = "Home";
    links = [
      {
        name = "LubeLogger";
        icon = "lubelogger";
        description = "Vehicle maintenance tracker";
      }
    ];
  };

  documentation = ./README.md;
}
