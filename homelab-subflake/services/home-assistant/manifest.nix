{ serviceName, ... }:
{
  module = ./home-assistant.nix;

  endpoints.web = {
    port = 8123;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  backups = {
    schedule = "daily";
    paths = [ "/var/lib/hass" ];
    impl = { lib, ... }:
      lib.localLib.mkBkp {
        paths = [ "/var/lib/hass" ];
        schedule = "daily";
        serviceName = "home-assistant";
      };
  };

  observability = {
    metrics.main = {
      impl = ./non-functional/metrics.nix;
      path = "/api/prometheus";
    };
    alerts.grafanaImpl = import ./non-functional/alerts.nix { inherit serviceName; };
  };

  dashboard = {
    category = "Home";
    links = [
      {
        description = "The brains of the smart home";
        icon = "home-assistant";
        name = "Home assistant";
      }
    ];
  };
}
