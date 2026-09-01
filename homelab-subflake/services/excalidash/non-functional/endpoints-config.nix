endpoints:
{ lib, ... }:
{
  services.excalidash = {
    listenHost = lib.homelab.getOwnIpInNetwork "backbone-inner";
    listenPort = endpoints.web.port;
  };
}
