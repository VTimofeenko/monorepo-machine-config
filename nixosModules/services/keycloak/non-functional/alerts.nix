{ serviceName, ... }:
{ lib, ... }:
{
  Emergency = [
    {
      title = "${serviceName} service down";
      query = "up{job=\"${serviceName}-srv-scrape\"}";
    }
    {
      title = "DB Pool Exhausted";
      query = "agroal_awaiting_count > 0";
      addVector = true;
    }
    {
      title = "disk almost full";
      query =
        let
          label = "mountpoint=\"/\", host=\"${serviceName |> lib.homelab.getServiceHost}\"";
        in
        "(((node_filesystem_avail_bytes{${label}} * 100) / node_filesystem_size_bytes{${label}}) < 10)";
      addVector = true;
    }
  ];
  Alert = [
    {
      title = "high error rate";
      query = "sum(rate(http_server_requests_seconds_count{status=~\"5..\"}[5m])) / sum(rate(http_server_requests_seconds_count[5m])) > 0.05";
      addVector = true;
    }
    # This might require tweaking
    {
      title = "unexpected user events";
      query = "rate(keycloak_user_events_total{error!=\"\"}[5m]) >= 1";
      addVector = true;
    }
  ];
}
