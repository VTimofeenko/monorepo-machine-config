{ serviceName, ... }:
{
  module = ./home-assistant.nix;

  endpoints.web = {
    port = 8123;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  backups = {
    paths = [ "/var/lib/hass" ];
  };

  observability = {
    metrics.main = {
      impl = ./non-functional/metrics.nix;
      path = "/api/prometheus";
    };
    alerts.prometheusImpl = ./non-functional/alerts.nix;
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

  roamNodes = [ "011c96d0-94f0-40e2-b85a-bfb65008a1dc" ];
}
