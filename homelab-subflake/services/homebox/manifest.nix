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
    schedule = "daily";
    paths = [ "/var/lib/homebox/data" ];
    impl = { lib, ... }:
      lib.localLib.mkBkp {
        paths = [ "/var/lib/homebox/data" ];
        schedule = "daily";
        serviceName = "homebox";
      };
  };

  observability = {
    alerts.grafanaImpl = import ./non-functional/alerts.nix { inherit serviceName; };
  };

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
