endpoints:
{ lib, ... }:
{
  services.spoolman = {
    listen = lib.homelab.getOwnIpInNetwork "backbone-inner";
    inherit (endpoints.web) port;
  };
}
