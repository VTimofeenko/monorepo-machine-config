{ serviceName, ... }:
{
  Emergency = [
    {
      title = "Auth DNS is down";
      expr = ''absent(up{resource="srv:${serviceName}"}) or up{resource="srv:${serviceName}"} == 0'';
      description = "NSD is not responding. Authoritative DNS is unavailable.";
    }
  ];
  Error = [
    {
      title = "High SERVFAIL rate";
      # sum by instance: only the numerator has `rcode`, so a plain division matches nothing.
      # Own zones only, so a low floor; it keeps one retrying client off the quiet instance.
      expr = ''
        (
          sum by (instance) (rate(nsd_queries_by_rcode_total{rcode="SERVFAIL",resource="srv:${serviceName}"}[5m]))
            / sum by (instance) (rate(nsd_queries_total{resource="srv:${serviceName}"}[5m]))
          > 0.05
        )
        and sum by (instance) (increase(nsd_queries_by_rcode_total{rcode="SERVFAIL",resource="srv:${serviceName}"}[5m])) > 5
      '';
      description = "More than 5% (and over 5) of responses in 5m are SERVFAIL. NSD may be misconfigured or zones may be broken.";
    }
    {
      title = "Answer TX failures";
      expr = ''rate(nsd_answers_tx_failed_total{resource="srv:${serviceName}"}[5m]) > 0'';
      description = "NSD is failing to send answers to clients.";
    }
  ];
  Warning = [
    {
      title = "Queries dropped";
      expr = ''rate(nsd_queries_dropped_total{resource="srv:${serviceName}"}[5m]) > 0'';
      description = "NSD is dropping incoming queries. Server may be overloaded.";
    }
    {
      title = "No primary zones loaded";
      expr = ''nsd_zones_primary{resource="srv:${serviceName}"} == 0'';
      description = "NSD has no primary zones loaded. All zone data may have been lost.";
    }
  ];
}
