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

  # Homebox only pushes OTLP (no scrape endpoint), so it is covered by a probe
  observability = {
    probes = {
      enable = true;
      impl = ./non-functional/probes;
      prometheusImpl = ./non-functional/probes/prometheus.nix;
    };
    alerts.prometheusImpl = ./non-functional/alerts.nix;
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
