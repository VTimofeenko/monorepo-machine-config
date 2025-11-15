{ serviceName, ... }:
{ lib, ... }:
{
  Alert = [
    # service availability
    {
      title = "service down";
      query = "up{job=\"gitea-srv-scrape\"}";
    }
    # disk almost full
    {
      title = "disk almost full";
      query = "(vector(0) and on() (((node_filesystem_avail_bytes{mountpoint=\"/var/lib/gitea\"} * 100) / node_filesystem_size_bytes{mountpoint=\"/var/lib/gitea\"}) < 10)) or on() vector(1)";
    }
    # Sudden spike in proxy errors
    {
      title = "Spike in proxy errors";
      query = "(vector(0) and on() (irate(ssl_proxy_nginx_http_requests_total{domain=\"${
        serviceName |> lib.homelab.getServiceFqdn
      }\", result!=\"2xx_3xx_success\"}[3m]) > 0)) or on() vector(1) ";
    }
    # TODO: (needs new DB) query duration
  ];
}
