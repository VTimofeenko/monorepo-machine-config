{ port, serviceName, ... }:
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

  services.homepage-dashboard.allowedHosts = lib.homelab.getServiceFqdn serviceName;
}
