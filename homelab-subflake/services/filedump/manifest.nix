{ serviceName, ... }:
{
  module = ./filedump.nix;

  endpoints.web = {
    port = 80;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  sslProxyConfig = import ./non-functional/ssl.nix { inherit serviceName; };

  observability = { }; # TODO: implement, probe only

  dashboard = {
    category = "Home";
    links = [
      {
        icon = "filebrowser";
        name = "Filedump";
      }
    ];
  };
}
