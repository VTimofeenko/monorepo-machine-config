{ port, serviceName, ... }:
{
  config,
  lib,
  self,
  ...
}:
self.serviceModules.ssl-proxy.srvLib.mkStandardProxyVHost {
  inherit
    serviceName
    port
    config
    lib
    ;
}
