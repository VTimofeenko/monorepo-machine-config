/**
  This module retrieves the scrape targets from the new `manifest.nix`.

  I will start lightweight and add features from `./default.nix` as needed.
*/
{
  lib,
  data-flake,
  self,
  ...
}:
let
  serviceManifests =
    # Collect the service manifests from data-flake
    data-flake.serviceModules
    # Add manifests from self
    |> lib.mergeAttrs self.serviceModules;
in
{
  services.prometheus.scrapeConfigs =
    serviceManifests
    # Filter only ones that declare metrics
    # I might need to also disable if v.observability.enable is false...
    |> lib.filterAttrs (_: v: v.observability.metrics.enable or false)
    |> lib.mapAttrsToList (
      srvName: manifest: {
        job_name = "${srvName}-srv-scrape";
        scrape_interval = "30s";
        scheme = "https";
        metrics_path = manifest.observability.metrics.path;

        static_configs = [
          {
            targets = srvName |> lib.homelab.getServiceFqdn |> lib.singleton;
          }
        ];

        # TODO: this is effectively a one-off constant
        bearer_token = (lib.homelab.getServiceConfig srvName).metricsToken or null;
      }
    );

}
