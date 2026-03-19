endpoints: { ... }:
{
  services.nsd = {
    port = endpoints.dns.port;
    # NSD listens on localhost only for DNS queries - Unbound forwards authoritative queries to it
    interfaces = [ "127.0.0.1" ];
  };

}
