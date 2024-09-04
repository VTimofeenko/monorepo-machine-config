{ config, lib, ... }:
let
  inherit (lib.homelab) getOwnIpInNetwork getServiceMonitoring;
  srvName = "ntp";

  inherit (getServiceMonitoring srvName) scrapePort;
in
{
  services.ntpd-rs.settings.observability.metrics-exporter-listen =
    assert lib.assertMsg config.services.ntpd-rs.enable "ntpd-rs needs to be enabled";
    assert lib.assertMsg config.services.ntpd-rs.metrics.enable "ntpd-rs metrics need to be enabled";
    "${getOwnIpInNetwork "monitoring"}:${toString scrapePort}";

  networking.firewall.interfaces.monitoring.allowedTCPPorts = lib.singleton scrapePort;
}
