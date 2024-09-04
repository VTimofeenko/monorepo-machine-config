{ config, lib, ... }:
{
  services.ntpd-rs.settings.observability.metrics-exporter-listen =
    assert lib.assertMsg config.services.ntpd-rs.enable "ntpd-rs needs to be enabled";
    assert lib.assertMsg config.services.ntpd-rs.metrics.enable "ntpd-rs metrics need to be enabled";
    "${lib.homelab.getOwnIpInNetwork "monitoring"}:9975";
}
