{ port, serviceName }:
{
  config,
  lib,
  self,
  ...
}:
self.serviceModules.ssl-proxy.srvLib.mkStandardProxyVHost {
  inherit
    port
    serviceName
    config
    lib
    ;
}
