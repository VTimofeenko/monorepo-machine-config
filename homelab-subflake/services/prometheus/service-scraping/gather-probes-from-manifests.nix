/**
  This module retrieves the probe targets from the new `manifest.nix`.

  Unlike metric scraping, probe configurations are usually unique per service,
  so this module is only building imports.
*/
{ lib, ... }:
let
  serviceManifests = lib.homelab.getManifests;
in
{
  imports =
    serviceManifests
    # Filter only ones that declare probes
    |> lib.filterAttrs (_: v: v.observability.probes.enable or false)
    # Import the Prometheus implementation
    |> lib.mapAttrsToList (_: it: it.observability.probes.prometheusImpl);
}
