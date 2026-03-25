/**
  Creates a zone that will house all metrics for all services.

  For each service instance with observability.metrics in its manifest, creates
  A records pointing to all SSL proxy hosts for redundancy and load balancing.

  Example (with 2 SSL proxies):
  ```
    dns-1.metrics.<publicDomain>  IN A  192.168.1.100
    dns-1.metrics.<publicDomain>  IN A  192.168.1.101
    dns-2.metrics.<publicDomain>  IN A  192.168.1.100
    dns-2.metrics.<publicDomain>  IN A  192.168.1.101
  ```
*/

{ lib, ... }:
let
  inherit (lib.homelab.getManifest "auth-dns") srvLib;
  domain = "metrics.${lib.homelab.getSettings.publicDomainName}";

  # Pre-compute manifests with metrics to avoid repeated lookups
  manifestsWithMetrics =
    lib.homelab.getManifests
    |> lib.filterAttrs (_: manifest: manifest.observability.metrics or { } != { })
    |> lib.attrNames
    |> (map (name: lib.nameValuePair name true))
    |> lib.listToAttrs;
in
{
  services.nsd.zones.${domain}.data =
    [
      # Zone header
      (srvLib.mkZoneBase {
        inherit domain;
        nameserverIPs = (lib.homelab.networks.get "backbone-inner").dnsServers;
      })

      # A records for each service instance with metrics, pointing to all SSL proxies
      (lib.mapCartesianProduct ({ a, b }: srvLib.mkCNAMERecord a b) {
        a =
          # This goes back to service _instances_
          lib.homelab.services.getAll
          |> lib.filterAttrs (_: svcData: manifestsWithMetrics ? ${svcData.moduleName or ""})
          |> lib.attrNames;
        b =
          # Prometheus is the one that will be using this; Prometheus can talk over backbone-inner
          lib.homelab.hosts.getWithService "ssl-proxy"
          |> map (lib.flip lib.homelab.hosts.getFQDNInNetwork "backbone-inner");
      })
    ]
    |> lib.flatten
    |> lib.concatStringsSep "\n";
}
