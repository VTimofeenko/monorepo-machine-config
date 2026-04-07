{ lib, ... }:
{
  module = ./auth-dns.nix;

  # NSD (authoritative DNS) listens on localhost:5454
  # NOT exposed externally - Unbound (recursive DNS) forwards queries to NSD
  endpoints = {
    dns = {
      port = 5454;
      protocol = "udp";
    };
    metrics = {
      port = 8081;
      protocol = "tcp";
    };
  };

  # Configure NSD port and listen interface from endpoints
  endpointsConfig = import ./non-functional/endpoints-config.nix;

  # No firewall - NSD only listens on localhost, no network firewall rules needed

  multiInstance = true;

  # Zone generation library
  srvLib = import ./srv-lib.nix { inherit lib; };

  observability = {
    metrics.main = {
      impl = ./non-functional/metrics.nix;
      endpoint = "metrics";
    };
    alerts.prometheusImpl = ./non-functional/alerts.nix;
  };

  documentation = ./README.md;

  # No backups - zones are auto-generated from config
  # No SSL proxy - raw DNS protocol
  # No dashboard - backend service
}
