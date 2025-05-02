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
  extraConfig = ''
    client_max_body_size 500M;
  '';
  onlyHumans = true;
}
