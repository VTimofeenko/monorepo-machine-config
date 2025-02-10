{
  config,
  lib,
  self,
  ...
}:
self.serviceModules.ssl-proxy.srvLib.mkStandardProxyVHost {
  serviceName = "healthchecks";
  port = 8000;
  inherit config lib;
}
