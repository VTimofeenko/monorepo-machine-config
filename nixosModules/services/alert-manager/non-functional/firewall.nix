{ servicePort, serviceName, ... }:
{ self, lib, ... }:
{
  services.prometheus.alertmanager = {
    port = servicePort;
    listenAddress = serviceName |> lib.homelab.getServiceInnerIP;
  };

  imports = [
    (self.serviceModules.ssl-proxy.srvLib.mkBackboneInnerFirewallRules {
      inherit lib;
      ports = [ servicePort ];
    })
  ];
}
