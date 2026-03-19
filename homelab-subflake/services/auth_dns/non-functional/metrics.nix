/**
  Observability module for `auth_dns` (NSD).

  The configuration (metrics-interface, metrics-port) is handled in
  endpoints-config.nix to access the endpoints data.

  The firewall rules are auto-generated from the metrics endpoint
  on the backbone-inner interface.
*/
{ lib, ... }:
let
  port = 5454; # TODO: make metrics implementation also an auto-applied function of endpoints like endpoints-config?
in
{
  # This module exists primarily to signal that metrics are enabled in the manifest
  # If metrics endpoint exists, configure it on the backbone-inner interface
  services.nsd.extraConfig = ''
    server:
        metrics-enable: yes
        metrics-interface: ${lib.homelab.getOwnIpInNetwork "backbone-inner"}
        metrics-port: ${toString port}
  '';
}
