{ serviceName, ... }:
{
  module = ./fava.nix;

  endpoints = {
    web = {
      port = 5001;
      protocol = "https";
    };
    webhook = {
      port = 9001;
      protocol = "tcp";
    };
    metrics = {
      port = 9002;
      protocol = "tcp";
    };
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  sslProxyConfig = import ./non-functional/ssl.nix { inherit serviceName; };

  observability.metrics.main = {
    impl = ./non-functional/observability/metrics/impl.nix;
    endpoint = "metrics";
  };

  storage.impl = ./non-functional/storage.nix;

  # backups = { paths = [ "/var/lib/fava" ]; }; # TODO

  dashboard = {
    category = "Home";
    links = [
      {
        name = "Fava";
        icon = "fava";
        description = "Beancount web interface";
      }
    ];
  };

  documentation = ./README.md;
}
