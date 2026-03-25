# Configure reverse DNS lookups on unbound side
{ lib, ... }:
let
  # Get NSD port from auth-dns manifest
  authDnsManifest = lib.homelab.getManifest "auth-dns";
  nsdPort = authDnsManifest.endpoints.dns.port;
in
{
  services.unbound.settings = {
    # Tell Unbound not to use default behavior for reverse DNS
    server.local-zone = [ "in-addr.arpa. nodefault" ];
    server.domain-insecure = [ "in-addr.arpa." ];

    # Forward all reverse DNS queries to NSD (authoritative)
    # If NSD doesn't have the zone, it returns NXDOMAIN
    stub-zone = [
      {
        name = "in-addr.arpa";
        stub-addr = [ "127.0.0.1@${toString nsdPort}" ];
      }
    ];
  };
}
