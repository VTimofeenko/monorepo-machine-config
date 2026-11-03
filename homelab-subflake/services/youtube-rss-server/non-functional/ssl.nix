{ serviceName, ... }:
{
  config,
  lib,
  self,
  ...
}:
let
  inherit (lib.homelab.getManifest serviceName) endpoints;
  # Service FQDNs CNAME to the proxy's LAN address, so miniflux arrives from its host's LAN IP
  # TODO: ACL
  minifluxIP =
    "miniflux" |> lib.homelab.getServiceHost |> lib.flip lib.homelab.getHostIpInNetwork "lan";
in
self.serviceModules.ssl-proxy.srvLib.mkStandardProxyVHost {
  inherit config lib serviceName;
  inherit (endpoints.web) port;
  onlyHumans = true;
  extraConfig = "allow ${minifluxIP};";
}
