{ ... }:
{
  module = ./unbound.nix;

  # Unbound (recursive DNS) listens on port 53
  # Exposed on LAN and other configured networks
  endpoints = {
    dns = {
      port = 53;
      protocol = "udp";
    };
    metrics = {
      port = 9167;
      protocol = "tcp";
    };
  };

  # Custom firewall - opens DNS port on configured network interfaces (not just backbone)
  firewall = ./non-functional/firewall.nix;

  observability = {
    # Unbound exporter metrics
    metrics.main = {
      impl = ./non-functional/metrics.nix;
    };

    alerts.grafanaImpl = import ./non-functional/alerts.nix;
    logging.impl = ./non-functional/logging.nix;
  };

  multiInstance = true;

  # Service library
  srvLib = import ./lib.nix;

  # No backups - stateless service
  # No storage - stateless service
}
