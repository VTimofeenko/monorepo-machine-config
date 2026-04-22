endpoints:
{ lib, ... }:
{
  services.linkwarden = {
    host = lib.homelab.getOwnIpInNetwork "backbone-inner";
    port = endpoints.web.port;
  };
}
