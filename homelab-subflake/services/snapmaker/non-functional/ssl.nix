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
  # Moonraker trusts the relay host, so the network position is the auth
  onlyHumans = true;
  # Multi-color gcode easily goes above the global limit
  extraConfig = "client_max_body_size 1G;";
}
