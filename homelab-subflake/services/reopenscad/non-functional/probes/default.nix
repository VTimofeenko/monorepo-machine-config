/**
  Lets the Prometheus host's blackbox exporter reach `/api/health` directly,
  bypassing the SSL proxy's human-only allowlist.
*/
{ lib, ... }:
let
  inherit (lib.homelab.getManifest "reopenscad") endpoints;
in
(lib.homelab.getSrvLib "prometheus").mkBackboneInnerFirewallRules {
  inherit lib;
  inherit (endpoints.web) port;
}
