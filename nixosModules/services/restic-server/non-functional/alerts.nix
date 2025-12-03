{ serviceName, ... }:
{ lib, ... }:
{
  # standard proxy alerts
  Alert = [
    {
      title = "Restic service down";
      query = "up{job=\"${serviceName}-srv-scrape\"}";
    }
    {
      title = "disk almost full";
      query =
        let
          label = "mountpoint=\"/var/lib/restic\", host=\"${serviceName |> lib.homelab.getServiceHost}\"";
        in
        "(((node_filesystem_avail_bytes{${label}} * 100) / node_filesystem_size_bytes{${label}}) < 10)";
      addVector = true;
    }
    {
      title = "Spike in proxy errors";
      query = "(vector(0) and on() (irate(ssl_proxy_nginx_http_requests_total{domain=\"${
        serviceName |> lib.homelab.getServiceFqdn
      }\", result!=\"2xx_3xx_success\"}[3m]) > 0)) or on() vector(1) ";
    }
  ];
}
