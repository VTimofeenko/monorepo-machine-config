endpoints:
{ lib, ... }:
{
  services.youtube-rss-server = {
    listenAddress = lib.homelab.getOwnIpInNetwork "backbone-inner";
    inherit (endpoints.web) port;
  };
}
