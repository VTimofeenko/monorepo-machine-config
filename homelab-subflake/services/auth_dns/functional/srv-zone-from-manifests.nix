/**
  Generates DNS records for the <publicDomain> zone from service manifests.

  Auto-generates:
  - A/CNAME records for each service pointing to SSL proxy or direct IP
  - For multi-instance services, creates records for each instance
  - `TXT` location records for service host information
*/
{
  lib,
  self,
  ...
}:
let
  inherit (lib.homelab.getSettings) publicDomainName;
  srvDomain = "${publicDomainName}";

  # Get all service manifests (including merged private ones)
  serviceManifests = self.serviceModules;

  # Get the SSL proxy hostname (where HTTPS services point to)
  # TODO: use the `getSSLProxy` function for multiple proxies
  sslProxyHost =
    "ssl-proxy"
    |> lib.homelab.getServiceHost  # e.g., "fluorine"
    |> (host: "${host}.home.arpa"); # Full FQDN

  # Generate DNS records for a single service instance
  # Returns null for localhost-only services (no `networkAccess`)

  mkServiceRecord = serviceName: manifest: instanceName:
    let
      # Check if this instance has network access by trying to get its IP
      # Services without `networkAccess` will fail, so we catch that
      hasNetworkAccess = builtins.tryEval (lib.homelab.getServiceInnerIP instanceName);
      hasNetworkAccess' = hasNetworkAccess.success;

      # Check if service has HTTPS endpoint
      hasHttpsEndpoint = manifest.endpoints ? web &&
                         (manifest.endpoints.web.protocol or null) == "https";

      # Determine record type and target
      recordType = if hasHttpsEndpoint then "CNAME" else "A";
      recordTarget = if hasHttpsEndpoint then
        sslProxyHost  # CNAME to SSL proxy
      else
        instanceName |> lib.homelab.getServiceInnerIP;  # A record to backbone-inner IP

      # Create the DNS record
      dnsRecord = "${instanceName} IN ${recordType} ${recordTarget}${
        if recordType == "CNAME" then "." else ""
      }";

      # Create TXT location record
      hostName = instanceName |> lib.homelab.getServiceHost;
      txtRecord = "_i.${instanceName} IN TXT @ ${hostName}";
    in
    if hasNetworkAccess' then
      { inherit dnsRecord txtRecord; }
    else
      null;  # Skip localhost-only services

  # Discover instances for a multi-instance service
  # Returns list of instance names (e.g., ["dns_1", "dns_2"])
  # Returns empty list if service is not deployed anywhere
  getInstancesForService = serviceName: manifest:
    if manifest.multiInstance or false then
      # Multi-instance: discover all instances from homelab library
      # by finding all services with matching moduleName
      lib.homelab.services.getAll
      |> lib.filterAttrs (_name: svcData: (svcData.moduleName or _name) == serviceName)
      |> lib.attrNames
    else
      # Single instance - check if it exists in deployed services
      if lib.homelab.services.getAll ? ${serviceName} then
        [ serviceName ]
      else
        [ ];  # Service not deployed anywhere

  # Generate records for all instances of a service
  mkServiceRecords = serviceName: manifest:
    let
      instances = getInstancesForService serviceName manifest;
    in
    instances
    |> map (instanceName: mkServiceRecord serviceName manifest instanceName);

  # Generate all service records
  allServiceRecords =
    serviceManifests
    # Filter out services with no endpoints (e.g., libraries, pure modules)
    |> lib.filterAttrs (_: v: v.endpoints or {} != {})
    |> lib.mapAttrsToList mkServiceRecords
    |> lib.flatten
    # Filter out null values (localhost-only services)
    |> builtins.filter (record: record != null);

  # Separate DNS records and TXT records
  dnsRecords = allServiceRecords |> map (r: r.dnsRecord);
  txtRecords = allServiceRecords |> map (r: r.txtRecord);

  # Combine into zone data
  zoneData =
    (dnsRecords |> lib.concatLines)
    + "\n\n"
    + (txtRecords |> lib.concatLines)
    + "\n";
in
{
  services.nsd.zones.${srvDomain}.data = lib.mkBefore zoneData;
}
