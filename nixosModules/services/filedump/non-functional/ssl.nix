{ serviceName, port }:
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
  allowiFrame = true;
}
