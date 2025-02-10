{
  config,
  lib,
  self,
  ...
}:
self.serviceModules.ssl-proxy.srvLib.mkStandardProxyVHost {
  serviceName = "restic-server";
  port = 8080;
  inherit config lib;
}
