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
  # Restic deals with big files
  extraConfig = ''
    client_max_body_size 500M;
  '';
}
