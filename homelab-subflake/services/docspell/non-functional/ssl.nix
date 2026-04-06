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
{
  imports = [
    (self.serviceModules.ssl-proxy.srvLib.mkStandardProxyVHost {
      inherit serviceName config lib;
      inherit (endpoints.web) port;
      extraConfig = ''
        client_max_body_size 100M;
      '';
      onlyHumans = true;
    })
  ];

  services.nginx.virtualHosts.${lib.homelab.getServiceFqdn serviceName}.locations."/watch-dir/" = {
    proxyPass = "http://${
      serviceName |> lib.homelab.getServiceInnerIP
    }:${endpoints.filemanager.port |> toString}/watch-dir/";
  };
}
