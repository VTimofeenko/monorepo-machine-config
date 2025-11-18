{
  config,
  lib,
  self,
  ...
}:
let
  inherit (lib.homelab) getOwnIpInNetwork getServiceFqdn;

  srvName = "nut-server";
in
{
  services.prometheus.exporters.nut = {
    enable =
      assert config.power.ups.mode == "netserver";
      true;
    listenAddress = getOwnIpInNetwork "backbone-inner";
    openFirewall = lib.mkForce false;

    # Exporter-specific services
    nutServer = getServiceFqdn srvName;
    nutVariables = [
      "battery.charge"
      "battery.voltage"
      "battery.voltage.nominal"
      "battery.runtime"
      "battery.runtime.low"
      "input.voltage"
      "input.voltage.nominal"
      "ups.load"
      "ups.status"
      "ups.test.result"
    ];
  };

  imports = [
    (self.serviceModules.prometheus.srvLib.mkBackboneInnerFirewallRules {
      inherit lib;
      ports = config.services.prometheus.exporters.nut.port;
    })
  ];
}
