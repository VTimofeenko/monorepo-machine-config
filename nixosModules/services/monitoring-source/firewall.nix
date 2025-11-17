{
  lib,
  config,
  self,
  ...
}:
let
  inherit (lib) pipe;
  inherit (lib.homelab) getServiceConfig;
  inherit (getServiceConfig "prometheus") exporters;
in
{
  networking.firewall.interfaces.monitoring.allowedTCPPorts = pipe exporters [
    (map (x: config.services.prometheus.exporters.${x}.port))
  ];

  imports = [
    (self.serviceModules.prometheus.srvLib.mkBackboneInnerFirewallRules {
      inherit lib;
      ports = exporters |> map (it: config.services.prometheus.exporters.${it}.port);
    })
  ];
}
