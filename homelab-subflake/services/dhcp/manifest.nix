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
    metrics.main = {
      impl = ./non-functional/metrics.nix;
      path = "/";
    };
  };

  # Storage and backups omitted - this is a stateless service
  # The DHCP leases are ephemeral and don't need backup
}
