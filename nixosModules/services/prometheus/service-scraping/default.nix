# Scrapes the individual services metrics
{ lib, config, ... }:
let
  inherit (lib.homelab) getHostIpInNetwork getServiceMonitoring getServiceSecrets;
  inherit (lib)
    pipe
    filterAttrs
    mapAttrs'
    nameValuePair
    removeSuffix
    ;

  # Attrset of srvName = { pathToSecret, nameOfAgeSecretAttribute };
  scrapeSecrets = pipe (getServiceSecrets "prometheus") [
    (filterAttrs (n: _: lib.hasSuffix "scrape-token" n)) # -> only some secrets. Relies on string parsing which is bad
    (mapAttrs' (
      n: v:
      nameValuePair (removeSuffix "-scrape-token" n) {
        pathToSecret = v.materialFile;
        nameOfAgeSecretAttribute = n;
      }
    ))
  ];
in
{
  services.prometheus.scrapeConfigs = lib.pipe config.my-data.services.all [
    (filterAttrs (_: v: v ? monitoring && v.monitoring.enable && v.monitoring ? scrapeUrl))
    # Extract the service <> scrapeUrl
    # Implementation note: technically all values don't need these functions but this will survive interface
    # changes
    (builtins.mapAttrs (
      srvName: v: {
        job_name = "${srvName}-srv-scrape";
        scrape_interval = "30s";
        static_configs = [
          {
            targets = lib.pipe srvName [
              # Try http
              lib.homelab.getServiceFqdn
              # Override if the exporter is a separate process
              # Leave in place otherwise
              (if v.monitoring.exporterSeparateFromService then _: null else lib.id)
              # Fall back to non http
              (
                x:
                let
                  ipAddress = getHostIpInNetwork v.onHost "monitoring";
                  # Try to retrieve the port from service monitoring; fall back to config
                  scrapePort =
                    (getServiceMonitoring srvName).scrapePort
                      or config.services.prometheus.exporters.${v.monitoring.exporterNixOption}.port;
                in
                if x == null then "${ipAddress}:${toString scrapePort}" else x
              )
              # Needs to be a list
              lib.singleton
            ];
            labels.nodeName = "${v.onHost}.home.arpa";
          }
        ];
        metrics_path =
          v.monitoring.scrapeUrl
            or config.services.prometheus.exporters.${v.monitoring.exporterNixOption}.telemetryPath;
        bearer_token = (lib.homelab.getServiceConfig srvName).metricsToken or null;
        bearer_token_file =
          if builtins.hasAttr srvName scrapeSecrets then
            config.age.secrets."${scrapeSecrets.${srvName}.nameOfAgeSecretAttribute}".path
          else
            null;
      }
    ))
    builtins.attrValues
  ];

  age.secrets = mapAttrs' (
    _: v:
    nameValuePair v.nameOfAgeSecretAttribute {
      file = v.pathToSecret;
      owner = config.users.users.prometheus.name; # This will fail if prometheus is disabled
    }
  ) scrapeSecrets;

  services.prometheus.checkConfig = "syntax-only"; # bearer_token_file does not work with this
}
