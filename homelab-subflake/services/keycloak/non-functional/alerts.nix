{ serviceName, lib, ... }:
let
  host = lib.homelab.getServiceHost serviceName;
  fsDiskLabel = ''mountpoint="/", host="${host}"'';
in
{
  Emergency = [
    {
      title = "service down";
      expr = ''absent(up{resource="srv:${serviceName}", job="keycloak-main-metrics"}) or up{resource="srv:${serviceName}", job="keycloak-main-metrics"} == 0'';
    }
    {
      title = "DB pool exhausted";
      expr = ''agroal_awaiting_count{resource="srv:${serviceName}"} > 0'';
      description = "Connections waiting for DB pool — service is degraded";
    }
  ];
  Alert = [
    {
      title = "SSL probe failed";
      expr = ''absent(ssl_probe_success{resource="srv:${serviceName}"}) or ssl_probe_success{resource="srv:${serviceName}"} == 0'';
      description = "Keycloak TLS handshake failing — SSO unavailable for all services";
    }
  ];
  Critical = [
    {
      title = "disk almost full";
      expr = "(node_filesystem_avail_bytes{${fsDiskLabel}} / node_filesystem_size_bytes{${fsDiskLabel}}) * 100 < 10";
      description = "Free disk space < 10%";
    }
  ];
  Warning = [
    {
      title = "auth error events";
      expr = ''rate(keycloak_user_events_total{resource="srv:${serviceName}", error!=""}[5m]) >= 1'';
      description = "Sustained authentication errors — possible brute force or misconfigured client";
    }
    {
      title = "DB pool no connections available";
      expr = ''agroal_available_count{resource="srv:${serviceName}"} == 0'';
      description = "No idle DB connections — pool approaching exhaustion";
    }
  ];
}
