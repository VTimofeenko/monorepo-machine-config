{ port, serviceName, ... }:
{ lib, self, ... }:
{
  services.prometheus = {
    listenAddress = lib.homelab.getServiceInnerIP serviceName;
    inherit port;
  };

  imports = [
    (self.serviceModules.ssl-proxy.srvLib.mkBackboneInnerFirewallRules {
      inherit lib;
      ports = [ port ];
    })
  ];
}
