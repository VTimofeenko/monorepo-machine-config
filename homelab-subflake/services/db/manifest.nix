{ ... }:
{
  module = ./postgresql.nix;

  endpoints = {
    db = {
      port = 5432;
      protocol = "tcp";
    };
    metrics = {
      port = 9187;
      protocol = "tcp";
    };
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;
  firewall = ./non-functional/firewall.nix;
  # TODO: firewall

  observability = {
    metrics.main = {
      impl = ./non-functional/metrics.nix;
      endpoint = "metrics";
    };
  };

  storage.impl = ./non-functional/storage.nix;

  backups = {
    paths = [ ];
    localDB = true;
  };
}
