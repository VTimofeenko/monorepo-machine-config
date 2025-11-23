/**
  Sets up vector to report its own metrics for `prometheus` to scrape.
*/
{ port, ... }:
{
  lib,
  self,
  ...
}:
{
  services.vector.settings = {
    sources.vector-metrics.type = "internal_metrics";

    sinks.vector-exporter = {
      type = "prometheus_exporter";
      inputs = [ "vector-metrics" ];
      address = "0.0.0.0:${port |> toString}";
    };

  };

  imports = [
    (self.serviceModules.prometheus.srvLib.mkBackboneInnerFirewallRules {
      inherit lib;
      ports = port;
    })
  ];
}
