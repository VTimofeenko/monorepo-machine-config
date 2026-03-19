/**
  Base NSD configuration for authoritative DNS.

  Sets up:
  - NSD daemon configuration
  - Base zone structures (SOA and NS records)
  - Imports functional modules that populate zone records
*/
{ lib, ... }:
let
  inherit (lib.homelab.getSettings) publicDomainName;
  srvLib = import ./srv-lib.nix;

  # Get nameserver IPs for zone SOA/NS records
  nameserverIPs = srvLib.getNameserverIPs { inherit lib; };

  # Base zone template with SOA and NS records
  mkZoneBase = domain: ttl: srvLib.mkZoneBase { inherit domain nameserverIPs lib ttl; };
in
{
  imports = lib.localLib.mkImportsFromDir ./functional;

  services.nsd = {
    enable = true;
    # Port and interface configuration in non-functional/endpoints-config.nix

    zones = {
      # Main service zone
      "srv.${publicDomainName}" = mkZoneBase "srv.${publicDomainName}" 1800;

      # Metrics zone (as per METRICS.md)
      "metrics.${publicDomainName}" = mkZoneBase "metrics.${publicDomainName}" 1800;

      # Backbone inner network zone
      "backbone-inner.${publicDomainName}" = mkZoneBase "backbone-inner.${publicDomainName}" 1800;

      # Legacy zones (being phased out)
      "mgmt.${publicDomainName}" = mkZoneBase "mgmt.${publicDomainName}" 1800;
      "db.${publicDomainName}" = mkZoneBase "db.${publicDomainName}" 1800;

      # LAN zone - Increased TTL to 3 days (259200 seconds) as per dns.org
      "home.arpa" = mkZoneBase "home.arpa" 259200;

      # Reverse zones are added by functional/reverse.nix
    };
  };
}
