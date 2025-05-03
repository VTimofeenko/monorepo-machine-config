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

  # Establish listening port
  services.healthchecks = {
    inherit port;
    listenAddress = lib.homelab.getOwnIpInNetwork "backbone-inner";
  };

}
