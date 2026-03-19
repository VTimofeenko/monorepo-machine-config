/**
  Generates DNS records for the metrics.<publicDomain> zone.

  All metrics endpoints point to the SSL proxy which handles routing to 
  the actual exporters.
*/
{ lib, self, ... }:
let
  inherit (lib.homelab.getSettings) publicDomainName;
  metricsDomain = "metrics.${publicDomainName}";

  # Get the SSL proxy hostname
  sslProxyHost = 
    "ssl-proxy"
    |> lib.homelab.getServiceHost
    |> (host: "${host}.home.arpa");

  # Get public service manifests
  serviceManifests = self.serviceModules;

  # Discover instances for a multi-instance service
  getInstancesForService = serviceName: manifest:
    if manifest.multiInstance or false then
      lib.homelab.services.getAll
      |> lib.filterAttrs (_name: svcData: (svcData.moduleName or _name) == serviceName)
      |> lib.attrNames
    else
      if lib.homelab.services.getAll ? ${serviceName} then
        [ serviceName ]
      else
        [ ];

  # Generate A records pointing to SSL proxy for each metrics-enabled instance
  mkMetricsRecords = srvName: manifest:
    let
      instances = getInstancesForService srvName manifest;
      hasMetrics = (manifest.observability.metrics or {}) != {};
    in
    if hasMetrics then
      map (instanceName: "${instanceName} IN CNAME ${sslProxyHost}.") instances
    else
      [ ];

  # Generate all metrics records
  allMetricsRecords = 
    serviceManifests
    |> lib.mapAttrsToList mkMetricsRecords
    |> lib.flatten;

  zoneData = 
    (allMetricsRecords |> lib.concatLines)
    + "\n";
in
{
  services.nsd.zones."${metricsDomain}".data = lib.mkBefore zoneData;
}
