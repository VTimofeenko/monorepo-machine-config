{ port, serviceName, ... }:
{
  lib,
  self,
  ...
}:
{
  # Listen only on backbone-inner
  services.pgadmin = {
    inherit port;
    settings.DEFAULT_SERVER = serviceName |> lib.homelab.getServiceInnerIP;
  };

  imports = [
    (self.serviceModules.ssl-proxy.srvLib.mkBackboneInnerFirewallRules {
      inherit lib;
      ports = [ port ];
    })
  ];
}
