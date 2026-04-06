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
  extraConfig = ''
    client_max_body_size 500M;
    # Required for exporter
    allow ${lib.homelab.hosts.getIPInNetwork (lib.homelab.getServiceHost serviceName) "lan"};
  '';
  onlyHumans = true;
}
