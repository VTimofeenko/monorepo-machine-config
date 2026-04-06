/**
  Generates nginx virtual hosts for all proxied services.

  For each manifest:
  - If sslProxyConfig is declared: use it (custom nginx config)
  - Else if https endpoints exist: auto-generate a standard proxy vhost
  - Otherwise: skip (TCP/UDP-only services don't need a vhost)

  Also handles old-format services with metrics on the web endpoint.
*/
{ lib, ... }:
let
  allManifests = lib.homelab.getManifests;
  srvLib = lib.homelab.getSrvLib "ssl-proxy";

  getSslProxyConfig =
    m:
    if m ? sslProxyConfig && m.sslProxyConfig != null then
      m.sslProxyConfig
    else if m ? ingress && m.ingress ? sslProxyConfig then
      m.ingress.sslProxyConfig
    else
      null;

  mkVhostImport =
    svcName: manifest:
    let
      explicit = getSslProxyConfig manifest;
    in
    if explicit != null then
      explicit
    else
      let
        httpsEndpoints = manifest.endpoints |> lib.filterAttrs (_: ep: ep.protocol == "https");
      in
      if httpsEndpoints == { } then
        null
      else
        let
          # Prefer "web" endpoint; fall back to first https endpoint
          endpoint = httpsEndpoints.web or (lib.head (lib.attrValues httpsEndpoints));
        in
        { config, lib, ... }:
        srvLib.mkStandardProxyVHost {
          serviceName = svcName;
          port = endpoint.port;
          inherit config lib;
        };

  # Old-format services expose metrics as a path on their web vhost.
  # New-format services get dedicated metrics subdomains (see metrics-vhosts.nix).
  metricsOnWebServices =
    allManifests
    |> lib.filterAttrs (_: v: v.observability.metrics.enable or false)
    |> lib.filterAttrs (_: v: !v.observability.metrics ? "port");
in
{
  imports =
    (
      allManifests
      |> lib.mapAttrsToList mkVhostImport
      |> lib.filter (x: x != null)
    )
    ++ (
      metricsOnWebServices
      |> lib.mapAttrsToList (
        svcName: srvManifest:
        srvLib.mkMetricsPathAllowOnlyPrometheus {
          serviceName = svcName;
          inherit lib;
          metricsPath =
            (srvManifest.observability.metrics.path or "/metrics")
            |> (it: if lib.isFunction it then it lib else it);
        }
      )
    );
}
