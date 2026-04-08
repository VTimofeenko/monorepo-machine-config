{ serviceName, ... }:
{
  module = ./impl.nix;

  endpoints.web = {
    port = 8080;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  sslProxyConfig = import ./non-functional/ssl.nix { inherit serviceName; port = 8080; };

  observability = {
    metrics.main.impl = ./non-functional/metrics.nix;
    alerts.prometheusImpl = ./non-functional/alerts.nix;
  };

  storage.impl = ./non-functional/storage.nix;
}
