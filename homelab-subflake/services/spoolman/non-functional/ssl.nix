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
  # Snapmaker U1 tracks filament usage through the API
  extraConfig = "allow ${lib.homelab.getHostIpInNetwork "snapmaker-u1" "iot"};";
}
