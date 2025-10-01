{ port, ... }:
{ lib, self, ... }:
{
  services.restic.server.listenAddress = port |> toString;
  imports = [
    (self.serviceModules.ssl-proxy.srvLib.mkBackboneInnerFirewallRules {
      inherit lib;
      ports = [ port ];
    })
  ];
}
