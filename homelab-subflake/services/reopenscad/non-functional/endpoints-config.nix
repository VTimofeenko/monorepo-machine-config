endpoints:
{ lib, ... }:
{
  services.reopenscad = {
    listenAddress = lib.homelab.getOwnIpInNetwork "backbone-inner";
    inherit (endpoints.web) port;
  };
}
