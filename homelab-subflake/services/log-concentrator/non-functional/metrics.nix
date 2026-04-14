/**
  Sets up vector to report its own metrics for `srv:prometheus` to scrape.
*/
{ lib, ... }:
{
  services.vector.settings = {
    sources.vector-metrics.type = "internal_metrics";

    sinks.vector-exporter = {
      type = "prometheus_exporter";
      inputs = [ "vector-metrics" ];
      address = "0.0.0.0:${(lib.homelab.getManifest "log-concentrator").endpoints.metrics.port |> toString}";
    };
  };
}
