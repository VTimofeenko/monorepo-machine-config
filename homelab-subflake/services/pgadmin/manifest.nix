{ serviceName, ... }:
{
  module = ./pgadmin.nix;

  endpoints.web = {
    port = 5050;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  sslProxyConfig = import ./non-functional/ssl.nix { inherit serviceName; };

  observability = { }; # TODO: implement, 200 probe only

  dashboard = {
    category = "Admin";
    links = [
      {
        description = "Database admin panel";
        icon = "pgadmin";
        name = "pgAdmin";
      }
    ];
  };
}
