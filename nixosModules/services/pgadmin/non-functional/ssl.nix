{ serviceName, port, ... }:
{
  config,
  lib,
  self,
  ...
}:
{
  imports = [
    (self.serviceModules.ssl-proxy.srvLib.mkStandardProxyVHost {
      onlyHumans = true;
      inherit
        port
        config
        lib
        serviceName
        ;
    })
  ];
}
