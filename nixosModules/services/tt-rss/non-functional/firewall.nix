/**
  Tiny tiny RSS comes with an nginx module. Rather than reimplementing the wheel, I
  will let the nixpkgs module handle the ingress.
*/
{ port, ... }:
{ lib, self, ... }:
{
  imports = [
    (self.serviceModules.ssl-proxy.srvLib.mkBackboneInnerFirewallRules {
      inherit lib;
      ports = [ port ];
    })
  ];
}
