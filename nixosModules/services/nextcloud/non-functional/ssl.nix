{ serviceName, port }:
{
  config,
  lib,
  self,
  ...
}:
self.serviceModules.ssl-proxy.srvLib.mkStandardProxyVHost {
  inherit
    config
    lib
    port
    serviceName
    ;
  extraConfig = ''
    client_max_body_size 500M;
    # Required for exporter
    allow ${serviceName |> lib.homelab.getServiceHost |> lib.homelab.hosts.getIPInNetwork "lan"};
  '';
  onlyHumans = true;
}
