{ serviceName, ... }:
{ lib, ... }:
{
  Emergency = [
    {
      title = "${serviceName} service down";
      query = "up{job=\"${serviceName}-srv-scrape\"}";
    }
    {
      title = "disk almost full";
      description = "Free disk space < 10%";
      query =
        let
          label = "mountpoint=~\"/var/lib/nextcloud.*\", host=\"${
            serviceName |> lib.homelab.getServiceHost
          }\"";
        in
        "(((node_filesystem_avail_bytes{${label}} * 100) / node_filesystem_size_bytes{${label}}) < 10)";
      addVector = true;
    }
  ];
  Alert = [
    {
      title = "Spike in proxy errors";
      query = "(vector(0) and on() (irate(ssl_proxy_nginx_http_requests_total{domain=\"${
        serviceName |> lib.homelab.getServiceFqdn
      }\", result!=\"2xx_3xx_success\"}[3m]) > 0)) or on() vector(1) ";
    }
  ];
}
