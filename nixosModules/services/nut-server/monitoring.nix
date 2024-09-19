{
  config,
  lib,
  ...
}:
let
  inherit (lib.homelab) getOwnIpInNetwork getServiceMonitoring getServiceFqdn;

  srvName = "nut-server";
in
{
  services.prometheus.exporters.${(getServiceMonitoring srvName).exporterNixOption} = {
    enable =
      assert config.power.ups.mode == "netserver";
      true;
    listenAddress = getOwnIpInNetwork "monitoring";
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
}
