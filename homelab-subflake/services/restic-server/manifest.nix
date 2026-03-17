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
    metrics.impl = ./non-functional/metrics.nix;
    alerts.grafanaImpl = import ./non-functional/alerts.nix { inherit serviceName; };
  };

  storage.impl = ./non-functional/storage.nix;
}
