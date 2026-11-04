{ serviceName, ... }:
{
  Emergency = [
    {
      title = "Service is down";
      expr = ''absent(up{resource="srv:${serviceName}"}) or up{resource="srv:${serviceName}"} == 0'';
    }
  ];
  Warning = [
    {
      title = "HTTP 5xx error rate";
      # Websocket subscribers on flaky Wi-Fi end up as stuck sessions that the
      # proxy reaps at 60s; ntfy counts those as 500s. Tolerate a handful.
      expr = ''increase(ntfy_http_requests_total{resource="srv:${serviceName}",http_code=~"5.."}[15m]) > 5'';
      for = "10m";
      description = "ntfy-sh is returning HTTP 5xx responses";
    }
    {
      title = "Message publish failures";
      expr = ''rate(ntfy_messages_published_failure{resource="srv:${serviceName}"}[5m]) > 0'';
      description = "ntfy-sh is failing to publish messages";
    }
  ];
}
