{ serviceName, ... }:
{
    module = ./gitea.nix;

    endpoints = {
      web = {
        port = 3000;
        protocol = "https";
      };
      ssh = {
        port = 22;
        protocol = "tcp";
      };
      metrics = {
        port = 3000;
        protocol = "tcp";
        path = "/metrics";
      };
    };

    endpointsConfig = import ./non-functional/endpoints-config.nix;

    sslProxyConfig = import ./non-functional/ssl.nix { inherit serviceName; sshPort = 22; webPort = 3000; };

    observability = {
      metrics.main.impl = ./non-functional/observability/metrics/impl.nix;
      alerts.grafanaImpl = import ./non-functional/observability/alerts.nix { inherit serviceName; };
    };

    storage.impl = ./non-functional/storage.nix;

    backups = rec {
      paths = [ "/var/lib/gitea" ];
      exclude = [
        "/var/lib/gitea/dump"
        "/var/lib/gitea/tmp"
      ];
      schedule = "daily";
      impl = { lib, ... }:
        lib.localLib.mkBkp {
          inherit paths exclude schedule;
          serviceName = "gitea";
        };
    };

    dashboard = {
      category = "Dev";
      links = [
        {
          description = "Local GitHub alternative";
          icon = "gitea";
          name = "Gitea";
        }
      ];
    };

    documentation = ./README.md;

    database = import ./non-functional/database.nix;
}
