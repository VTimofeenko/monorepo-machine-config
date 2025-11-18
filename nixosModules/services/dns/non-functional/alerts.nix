{
  Emergency = [
    {
      title = "DNS is down";
      query = "unbound_up or up{job=\"dns-srv-scrape\"}";
    }
  ];
  Alert = [
    {
      title = "High SERVFAIL rate";
      query = "(vector(0) and on() rate(unbound_answer_rcodes_total{rcode=\"SERVFAIL\"}[5m]) / rate(unbound_answer_rcodes_total[5m])>0.05) or on() vector(1)";
    }
    {
      title = "Slow upstreams";
      query = "(vector(0) and on() unbound_recursion_time_seconds_avg > 0.5) or on() vector(1)"; # 500 milliseconds
    }
  ];
}
