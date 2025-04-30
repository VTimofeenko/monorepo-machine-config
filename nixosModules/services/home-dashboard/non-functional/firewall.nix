{ port, ... }:
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
}
