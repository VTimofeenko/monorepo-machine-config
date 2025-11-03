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

  services.esphome = {
    inherit port;
    address = lib.homelab.getOwnIpInNetwork "backbone-inner";
  };
}
