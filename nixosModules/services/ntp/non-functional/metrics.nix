{ port, ... }:
{
  lib,
  self,
  ...
}:
{
  services.ntpd-rs = {
    metrics.enable = true;
    settings.observability.metrics-exporter-listen = "${
      "ntp" |> lib.homelab.getServiceInnerIP
    }:${toString port}";
  };

  imports = [
    (self.serviceModules.prometheus.srvLib.mkBackboneInnerFirewallRules {
      inherit lib port;
    })
  ];
}
