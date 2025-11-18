{
  lib,
  config,
  self,
  ...
}:
let
  inherit (lib.homelab) getServiceConfig;
  inherit (getServiceConfig "prometheus") exporters;
in
{
  imports = [
    (self.serviceModules.prometheus.srvLib.mkBackboneInnerFirewallRules {
      inherit lib;
      ports = exporters |> map (it: config.services.prometheus.exporters.${it}.port);
    })
  ];
}
