{ serviceName, ... }:
let
  # Grafana dashboard UIDs (folder srv:dns); alerts link to dns unless they name another
  dashboards = {
    dns = "58d1eec8-672d-4868-b6db-4b7bb7db10fe";
    failures = "6f91af01-1a97-411d-a9e8-475d988a1199";
    upstreams = "ae2f4572-657d-48a9-bdb2-731666a08162";
  };
in
{
  Emergency = [
    {
      title = "DNS is down";
      expr = ''absent(unbound_up{resource="srv:${serviceName}"}) or unbound_up{resource="srv:${serviceName}"} == 0'';
      description = "Unbound is not responding. DNS resolution is unavailable.";
    }
  ];
  Alert = [
    {
      title = "High SERVFAIL rate";
      # sum by instance: without it the ratio matches SERVFAIL against itself (always 1).
      # The count floor keeps one client retrying one dead name from tripping a quiet resolver.
      expr = ''
        (
          sum by (instance) (rate(unbound_answer_rcodes_total{rcode="SERVFAIL",resource="srv:${serviceName}"}[5m]))
            / sum by (instance) (rate(unbound_answer_rcodes_total{resource="srv:${serviceName}"}[5m]))
          > 0.05
        )
        and sum by (instance) (increase(unbound_answer_rcodes_total{rcode="SERVFAIL",resource="srv:${serviceName}"}[5m])) > 20
      '';
      description = "More than 5% (and over 20) of responses in 5m are SERVFAIL. Many names failing = upstreams, one name = a dead domain.";
      grafanaDashboardId = dashboards.failures;
    }
  ];
  Error = [
    {
      title = "DNSSEC bogus answers";
      expr = ''rate(unbound_answers_bogus{resource="srv:${serviceName}"}[5m]) > 0'';
      description = "Unbound is returning DNSSEC validation failures. May indicate a misconfigured domain or an attack.";
      grafanaDashboardId = dashboards.failures;
    }
  ];
  Warning = [
    {
      title = "Slow upstreams";
      expr = ''unbound_recursion_time_seconds_avg{resource="srv:${serviceName}"} > 0.5'';
      description = "Average upstream recursion time exceeds 500ms. Consider switching upstream resolvers.";
      grafanaDashboardId = dashboards.upstreams;
    }
    {
      title = "Request queue overflow";
      expr = ''rate(unbound_request_list_exceeded_total{resource="srv:${serviceName}"}[5m]) > 0'';
      description = "Unbound is dropping queries due to a full request queue. Service may be overloaded.";
    }
    {
      title = "Unwanted replies";
      expr = ''rate(unbound_unwanted_replies_total{resource="srv:${serviceName}"}[5m]) > 0'';
      description = "Unbound is receiving replies that match no pending query. Possible cache poisoning attempt on the LAN.";
      grafanaDashboardId = dashboards.upstreams;
    }
  ];
}
|> builtins.mapAttrs (_: v: v |> map (it: { grafanaDashboardId = dashboards.dns; } // it))
