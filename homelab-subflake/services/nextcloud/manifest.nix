{ serviceName, ... }:
{
  module = ./nextcloud.nix;

  endpoints = {
    web = {
      port = 80;
      protocol = "https";
    };
    metrics = {
      port = 9205;
      protocol = "tcp";
    };
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  sslProxyConfig = import ./non-functional/ssl.nix { inherit serviceName; };

  observability = {
    metrics.main = {
      impl = ./non-functional/metrics.nix;
      path = "/metrics";
      endpoint = "metrics";
    };
    alerts.prometheusImpl = ./non-functional/alerts.nix;
  };

  backups = {
    paths = [ "/var/lib/nextcloud" ];
    exclude = [ "appdata_ochcggcdayyl/preview" ];
    impl = { lib, ... }:
      lib.localLib.mkBkp {
        paths = [ "/var/lib/nextcloud" ];
        exclude = [ "appdata_ochcggcdayyl/preview" ];
        serviceName = "nextcloud";
      };
  };

  dashboard = {
    category = "Home";
    links = [
      {
        icon = "nextcloud";
        name = "Nextcloud";
      }
    ];
  };

  storage.impl = ./non-functional/storage.nix;
}
