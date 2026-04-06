endpoints: { lib, ... }:
{
  services.docspell-restserver.bind = {
    address = lib.homelab.getOwnIpInNetwork "backbone-inner";
    port = endpoints.web.port;
  };
}
