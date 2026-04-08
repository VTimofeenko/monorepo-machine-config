{ serviceName, lib, ... }:
let
  daysToExpire = ''floor((ssl_cert_not_after{resource="srv:${serviceName}",cn="*.${lib.homelab.getSettings.publicDomainName}",cert_type="central"} - time()) / 86400)'';
in
{
  Emergency = [
    {
      title = "SSL proxy service down";
      expr = ''absent(up{resource="srv:${serviceName}"}) or up{resource="srv:${serviceName}"} == 0'';
    }
  ];
  Alert = [
    {
      title = "SSL cert expiring very soon";
      expr = ''${daysToExpire} < 2'';
      description = "SSL certificate will expire in less than 2 days";
    }
  ];
  Warning = [
    {
      title = "SSL proxy upstream errors";
      expr = ''rate(ssl_proxy_nginx_http_requests_total{resource="srv:${serviceName}",result!="2xx_3xx_success"}[5m]) > 0.01'';
      description = "More than 1% of proxied requests are failing";
    }
  ];
  Informational = [
    {
      title = "Renew SSL cert";
      expr = ''${daysToExpire} < 15'';
      description = "SSL certificate will expire in less than 15 days";
    }
  ];
}
