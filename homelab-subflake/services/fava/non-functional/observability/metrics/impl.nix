{ lib, ... }:
{
  services.fava-helper.settings.metrics = {
    query_interval = "5m";
    queries = lib.homelab.getServiceConfig "fava" |> (c: c.metricsQueries or [ ]);
  };
}
