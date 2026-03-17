{ serviceName, ... }:
{ lib, ... }:
{
  Emergency = [
    {
      title = "Scrape is down";
      query = "up{job=\"${serviceName}-srv-scrape\"}";
      description = "Cannot retrieve healthchecks status. Check network connection.";
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
  Error = [
    {
      title = "Backup checks are down";
      query = "hc_check_up{name=~\".*-backup$\"}";
    }
  ];
}
