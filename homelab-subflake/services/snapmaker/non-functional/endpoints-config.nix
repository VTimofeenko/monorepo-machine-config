endpoints:
{ lib, ... }:
let
  listenOn = endpoint: [
    {
      addr = lib.homelab.getOwnIpInNetwork "backbone-inner";
      inherit (endpoint) port;
    }
  ];
in
{
  services.nginx.virtualHosts = {
    snapmaker-relay-web.listen = listenOn endpoints.web;
    snapmaker-relay-metrics.listen = listenOn endpoints.metrics;
  };
}
