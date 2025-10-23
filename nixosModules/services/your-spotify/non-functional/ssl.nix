/**
  This service uses nginx to serve the main web directory.
*/
{ serviceName, ... }:
let
  port = 80;
in
{
  config,
  lib,
  self,
  ...
}:
self.serviceModules.ssl-proxy.srvLib.mkStandardProxyVHost {
  inherit
    config
    lib
    port
    serviceName
    ;
}
