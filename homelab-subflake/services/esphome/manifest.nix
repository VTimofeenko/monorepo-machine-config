{ lib, serviceName, ... }:
{
  module = ./esphome.nix;

  endpoints.web = {
    port = 6052;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  sslProxyConfig = import ./non-functional/ssl.nix { inherit serviceName; };

  backups = {
    schedule = "daily";
    paths = [ "/var/lib/esphome/*.yaml" ];
    impl = { lib, ... }:
      lib.localLib.mkBkp {
        paths = [ "/var/lib/esphome/*.yaml" ];
        schedule = "daily";
        serviceName = "esphome";
      };
  };

  dashboard = {
    category = "Dev";
    links = [
      {
        description = "Firmware manager for all the random esp32s";
        icon = "esphome";
        name = "ESPhome";
      }
    ];
  };
}
