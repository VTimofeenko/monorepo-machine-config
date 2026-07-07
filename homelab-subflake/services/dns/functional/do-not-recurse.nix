/**
  Configures special-use zones (RFC 6761/8375/9476) to not recurse upstream.
*/
{
  services.unbound.settings.server.local-zone = [
    "local. static"
    "internal. static" # RFC 9476 - reserved for internal use, upstreams often SERVFAIL it
  ];
}
