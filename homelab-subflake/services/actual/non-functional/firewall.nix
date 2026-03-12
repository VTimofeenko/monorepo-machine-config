{ port, ... }:
{ self, lib, ... }:
{
  services.actual.settings = { inherit port; };
  imports = [
    (self.serviceModules.ssl-proxy.srvLib.mkBackboneInnerFirewallRules {
      inherit lib;
      ports = [ port ];
    })
  ];
}
