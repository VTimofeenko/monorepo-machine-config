/**
  Retrieves scrape targets from service manifests.

  Generates one scrape job per (service, exporter) pair. Multi-instance
  services (e.g. `dns-1`, `dns-2`) appear as multiple targets within the same job.
  All targets are scraped via the SSL proxy at
  `<instance>.metrics.<publicDomain>/metrics/<exporterName>`.
*/
{ lib, ... }:
{
  services.prometheus.scrapeConfigs =
    lib.homelab.getManifests
    # Filter only for services that declare metrics
    # If a service is "alien" (e.g. `rsync-net`) – it will have a dedicated
    # SERVICE object for its metrics
    |> lib.filterAttrs (_: m: m.observability.metrics != { })
    # Construct (service, exporter) jobs where multi-instance services appear
    # as multiple `static_configs` targets within the same job.
    # This relies on:
    # 1. `srv:ssl-proxy` handling the domains and path-based routing
    # 2. `srv:auth-dns` resolving the instance names
    |> lib.mapAttrsToList (
      srvName: manifest:
      manifest.observability.metrics
      |> lib.mapAttrsToList (
        exporterName: _: {
          job_name = "${srvName}-${exporterName}-metrics";
          scheme = "https";
          scrape_interval = "30s";
          metrics_path = "/metrics/${exporterName}";
          static_configs =
            lib.homelab.services.getInstances srvName
            |> map (instanceName: {
              targets = [ (lib.homelab.services.getServiceMetricsFqdn instanceName) ];
              labels = {
                service = srvName;
                instance = instanceName;
                exporter = exporterName;
              };
            });
        }
      )
    )
    |> lib.flatten;
}
