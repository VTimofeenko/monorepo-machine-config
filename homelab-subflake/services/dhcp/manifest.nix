{ ... }:
{
  # Main service module
  module = ./kea.nix;

  endpoints = {
    dhcp = {
      port = 67;
      protocol = "udp";
    };
    metrics = {
      port = 9547;
      protocol = "tcp";
    };
  };

  # Custom firewall configuration for DHCP port on LAN interface
  firewall = ./non-functional/firewall.nix;

  # Observability configuration
  observability = {
    alerts.prometheusImpl = ./non-functional/alerts.nix;
    logging.units = [ "kea-dhcp4-server.service" ];
    metrics.main = {
      impl = ./non-functional/metrics.nix;
      path = "/";
      units = [ "prometheus-kea-exporter.service" ];
    };
  };
}
