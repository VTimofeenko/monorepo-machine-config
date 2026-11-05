{ serviceName, ... }:
{
  config,
  lib,
  self,
  ...
}:
let
  inherit (lib.homelab.getManifest serviceName) endpoints;
in
self.serviceModules.ssl-proxy.srvLib.mkStandardProxyVHost {
  inherit config lib serviceName;
  inherit (endpoints.web) port;
  onlyHumans = true;
  # STL uploads take up to 128 MiB and 300 s; renders can queue for 60 s before compute starts
  extraConfig = ''
    client_max_body_size 129m;
    proxy_read_timeout 300s;
    proxy_send_timeout 300s;
  '';
}
