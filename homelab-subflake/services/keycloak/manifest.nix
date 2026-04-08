{ serviceName, ... }:
{
  module = ./keycloak.nix;

  endpoints = {
    web = {
      port = 443;
      protocol = "https";
    };
    metrics = {
      port = 9000;
      protocol = "tcp";
    };
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  # Custom firewall: Keycloak handles its own SSL
  firewall = ./non-functional/firewall.nix;


  observability = {
    metrics.main = {
      impl = ./non-functional/metrics.nix;
    };
    alerts.grafanaImpl = import ./non-functional/alerts.nix { inherit serviceName; };
    probes = {
      enable = true;
      prometheusImpl = ./non-functional/probes/prometheus.nix;
    };
  };

  backups = {
    paths = [ ];
    impl =
      { lib, ... }:
      lib.localLib.mkBkp {
        paths = [ ];
        inherit serviceName;
        localDB = true; # Everything in database
      };
  };

  dashboard = {
    category = "Admin";
    links = [
      {
        description = "SSO";
        icon = "keycloak";
        name = "Keycloak";
      }
    ];
  };
}
