{ port, serviceName }:
{
  lib,
  self,
  ...
}:
{
  imports = [
    (self.serviceModules.ssl-proxy.srvLib.mkBackboneInnerFirewallRules {
      inherit lib;
      ports = [ port ];
    })
  ];

  services.nginx.virtualHosts.${(lib.homelab.getService serviceName).fqdn}.listenAddresses =
    lib.homelab.getOwnIpInNetwork "backbone-inner" |> lib.singleton;
}
