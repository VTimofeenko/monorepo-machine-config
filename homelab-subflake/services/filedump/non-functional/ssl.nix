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
  allowiFrame = true;
}
