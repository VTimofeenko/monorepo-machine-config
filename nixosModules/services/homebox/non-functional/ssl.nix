{
  config,
  lib,
  self,
  ...
}:
self.serviceModules.ssl-proxy.srvLib.mkStandardProxyVHost {
  serviceName = "homebox";
  port = 7745;
  onlyHumans = true;
  inherit config lib;
}
