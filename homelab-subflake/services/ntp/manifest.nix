{ lib, serviceName, ... }:
{
  module = ./service.nix;

  endpoints = {
    ntp = {
      port = 123;
      protocol = "udp";
    };
    metrics = {
      port = 9975;
      protocol = "tcp";
    };
  };

  # Custom firewall needed - opens UDP 123 on LAN interface (not backbone-inner)
  firewall = ./non-functional/firewall.nix;

  observability = {
    metrics.main = {
      impl = ./non-functional/metrics.nix;
      path = "/";
      endpoint = "metrics";
    };
    alerts.prometheusImpl = ./non-functional/alerts.nix;
  };
}
