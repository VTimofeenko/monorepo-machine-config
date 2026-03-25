# Configure reverse DNS lookups on unbound side
{ lib, ... }:
let
  # Get reverse zone information from `auth-dns` manifest
  # This ensures `dns` and `auth-dns` stay in sync on which zones exist
  authDnsManifest = lib.homelab.getManifest "auth-dns";
  nsdPort = authDnsManifest.endpoints.dns.port;

  # Get reverse zones from `auth-dns` (single source of truth)
  inherit (authDnsManifest.srvLib.getReverseZones) reverseZones parentZones;
in
{
  services.unbound.settings = {
    # Set parent zones to `nodefault` to prevent default local-data
    server.local-zone = map (zone: "${zone} nodefault") parentZones;
    server.domain-insecure = parentZones;

    # Forward specific reverse zones to NSD (authoritative)
    forward-zone = map (name: {
      inherit name;
      forward-addr = "127.0.0.1@${toString nsdPort}";
    }) reverseZones;
  };
}
