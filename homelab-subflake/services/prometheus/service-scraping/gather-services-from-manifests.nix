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
    |> lib.recursiveUpdate self.serviceModules;
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
        metrics_path =
          (manifest.observability.metrics.path or "/metrics")
          |> (it: if builtins.isFunction it then it lib else it);

        static_configs =
          let
            srvScrapeTargets =
              if srvName == "dns" then
                [
                  "dns_1"
                  "dns_2"
                ]
              else
                srvName |> lib.toList;
          in
          srvScrapeTargets
          |> map (it: {
            targets =
              if metricsPartOfService then
                (it |> lib.homelab.getServiceFqdn) |> lib.toList
              else
                let
                  # Cast single port as a list to simplify code later
                  ports = (manifest.observability.metrics.port or manifest.observability.metrics.ports) |> lib.toList;
                in
                map (port: "${it |> lib.homelab.getServiceInnerIP}:${toString port}") ports;
            labels.host = it |> lib.homelab.getServiceHost;
          });

        # TODO: this is effectively a one-off constant
        bearer_token = (lib.homelab.getServiceConfig srvName).metricsToken or null;
      }
    );

}
