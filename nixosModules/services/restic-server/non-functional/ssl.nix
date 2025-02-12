{
  config,
  lib,
  self,
  ...
}:
self.serviceModules.ssl-proxy.srvLib.mkStandardProxyVHost {
  serviceName = "restic-server";
  port = 8080;
  # Restic deals with big files
  extraConfig = ''
    client_max_body_size 500M;
  '';
  inherit config lib;
}
