{ serviceName, ... }:
{
  module = ./homebox.nix;

  endpoints.web = {
    port = 7745;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  sslProxyConfig = import ./non-functional/ssl.nix { inherit serviceName; };

  backups = {
    paths = [ "/var/lib/homebox/data" ];
  };

  observability = { }; # TODO: implement probe and metrics https://homebox.software/en/advanced/opentelemetry/

  dashboard = {
    category = "Home";
    links = [
      {
        description = "Stuff @ home";
        icon = "homebox";
        name = "Homebox";
      }
    ];
  };
}
