{ serviceName, ... }:
{
  Emergency = [
    {
      title = "SSL proxy service down";
      expr = ''absent(up{resource="srv:${serviceName}"}) or up{resource="srv:${serviceName}"} == 0'';
    }
  ];
  Warning = [
    {
      title = "SSL proxy upstream errors";
      expr = ''rate(ssl_proxy_nginx_http_requests_total{resource="srv:${serviceName}",result!="2xx_3xx_success"}[5m]) > 0.01'';
      description = "More than 1% of proxied requests are failing";
    }
  ];
}
