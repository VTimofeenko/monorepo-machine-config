/**
  This module retrieves the probe targets from the new `manifest.nix`.

  Unlike metric scraping, probe configurations are usually unique per service, so this module is building imports.
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
  imports =
    serviceManifests
    # Filter only ones that declare probes
    |> lib.filterAttrs (_: v: v.observability.probes.enable or false)
    # Import the Prometheus implementation
    |> lib.mapAttrsToList (_: it: it.observability.probes.prometheusImpl);
}
