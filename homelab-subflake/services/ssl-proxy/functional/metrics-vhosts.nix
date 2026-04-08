/**
  Generates per-service metrics nginx vhosts.

  For each service with `observability.metrics`, creates an nginx vhost at
    <instance>.metrics.<publicDomain>
  with path-based routing per exporter at /metrics/<exporterName>.
  Access is restricted to Prometheus only.
*/
{ config, lib, ... }:
let
  prometheusInnerIP = lib.homelab.getServiceInnerIP "prometheus";

  # Infer which endpoint an exporter uses.
  # Priority: explicit endpoint > endpoint named "metrics" > first https endpoint
  inferEndpoint =
    endpoints: exporter:
    if exporter.endpoint != null then
      endpoints.${exporter.endpoint}
    else if endpoints ? metrics then
      endpoints.metrics
    else
      endpoints
      |> lib.filterAttrs (_: ep: ep.protocol == "https")
      |> lib.attrValues
      |> lib.head;

  mkMetricsVhost =
    instanceName: manifest:
    let
      innerIP = lib.homelab.getServiceInnerIP instanceName;
      fqdn = lib.homelab.services.getServiceMetricsFqdn instanceName;

      metricsLocations = manifest.observability.metrics
        |> lib.mapAttrs' (
          exporterName: exporter:
          let
            endpoint = inferEndpoint manifest.endpoints exporter;
          in
          lib.nameValuePair "/metrics/${exporterName}" {
            proxyPass = "http://${innerIP}:${toString endpoint.port}${exporter.path}";
            extraConfig = ''
              allow ${prometheusInnerIP};
              deny all;
            '';
          }
        );

      probeLocation = lib.optionalAttrs (manifest.endpoints ? probe) {
        "/probe" = {
          proxyPass = "http://${innerIP}:${toString manifest.endpoints.probe.port}";
          extraConfig = ''
            allow ${prometheusInnerIP};
            deny all;
          '';
        };
      };
    in
    {
      "${fqdn}" = {
        forceSSL = true;
        inherit (config.services.homelab.ssl-proxy) listenAddresses;
        sslCertificate = config.age.secrets."ssl-cert".path;
        sslCertificateKey = config.age.secrets."ssl-key".path;
        locations = metricsLocations // probeLocation;
      };
    };
in
{
  services.nginx.virtualHosts =
    lib.homelab.getManifests
    |> lib.filterAttrs (_: m: m.observability.metrics != { } || m.endpoints ? probe)
    |> lib.mapAttrsToList (
      modName: manifest:
      lib.homelab.services.getInstances modName
      |> map (instanceName: mkMetricsVhost instanceName manifest)
    )
    |> lib.flatten
    |> lib.mergeAttrsList;
}
