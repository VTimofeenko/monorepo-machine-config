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
# Management UI has no auth of its own
self.serviceModules.ssl-proxy.srvLib.mkStandardProxyVHost {
  inherit config lib serviceName;
  inherit (endpoints.web) port;
  onlyHumans = true;
}
