{
  config,
  lib,
  self,
  ...
}:
let
  serviceName = "keycloak";
  port = 443;
in
{
  imports = [
    (self.serviceModules.ssl-proxy.srvLib.mkStandardProxyVHost {
      inherit serviceName port;
      inherit config lib;
    })
    # Keycloak only listens on SSL. Protocol matters.
    {
      services.nginx.virtualHosts."${serviceName |> lib.homelab.getServiceFqdn}".locations."/".proxyPass =
        lib.mkForce "https://${serviceName |> lib.homelab.getServiceInnerIP}:${port |> toString}";
    }
  ];
}
