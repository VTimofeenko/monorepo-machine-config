{ port, ... }:
{ self, lib, ... }:
{
  services.web-receipt-printer.port = port;
  imports = [
    (self.serviceModules.ssl-proxy.srvLib.mkBackboneInnerFirewallRules {
      inherit lib;
      ports = [ port ];
    })
  ];
}
