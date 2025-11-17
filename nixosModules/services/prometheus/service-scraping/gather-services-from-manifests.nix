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
      srvName: manifest:
      let
        # Decide whether the metrics endpoint is part of the service or there's a separate exporter
        metricsPartOfService =
          !(manifest.observability.metrics ? "port" || manifest.observability.metrics ? "ports");
      in
      {
        job_name = "${srvName}-srv-scrape";
        scrape_interval = "30s";
        scheme = if metricsPartOfService then "https" else "http";
        metrics_path = manifest.observability.metrics.path;

        static_configs = [
          {
            targets =
              (
                # Metrics part of the service
                if metricsPartOfService then
                  srvName |> lib.homelab.getServiceFqdn
                # Single port for a single exporter
                else if manifest.observability.metrics |> builtins.hasAttr "port" then
                  (srvName |> lib.homelab.getServiceInnerIP) + ":${toString manifest.observability.metrics.port}"
                # Multiple exporters
                else
                  manifest.observability.metrics.ports
                  |> map (it: "${srvName |> lib.homelab.getServiceInnerIP}:${toString it}")
              )
              |> lib.toList;
          }
        ];

        # TODO: this is effectively a one-off constant
        bearer_token = (lib.homelab.getServiceConfig srvName).metricsToken or null;
      }
    );

}
