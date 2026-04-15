# Merges public and private service manifests using NixOS module system

{ lib }:
let
  inherit (builtins) trace filter;

  manifestOptionsModule = import ./manifest-options.nix;

  # Takes unevaluated manifest modules and returns evaluated attrset
  mergeServiceManifests =
    publicServices: privateServices:
    let
      allNames = lib.unique (builtins.attrNames publicServices ++ builtins.attrNames privateServices);

      mergeOne =
        serviceName:
        let
          publicMod = publicServices.${serviceName} or null;
          privateMod = privateServices.${serviceName} or null;

          hasPublic = publicMod != null;
          hasPrivate = privateMod != null;

          # Debug logging
          _ = trace "[merge-manifests] ${serviceName}: public=${toString hasPublic} private=${toString hasPrivate}" null;

          # Build module list
          modules = filter (m: m != null) [
            manifestOptionsModule
            publicMod
            privateMod
          ];

          # Evaluate modules with serviceName in scope
          evaluated = lib.evalModules {
            inherit modules;
            specialArgs = { inherit serviceName; };
          };

          # Extract the manifest attrset
          manifestData = evaluated.config;

          # Auto-assemble .default field from manifest components

          # module is either null or a list (custom merge collected multiple definitions)
          allModules = if manifestData.module == null then [ ] else lib.toList manifestData.module;

          # endpointsModule: custom impl if provided
          endpointsModule =
            if manifestData.endpointsConfig != null then
              if lib.isAttrs manifestData.endpointsConfig && !lib.isFunction manifestData.endpointsConfig then
                let
                  _ = builtins.trace "WARNING: [${serviceName}] endpointsConfig is a set, not a function - passing through as-is" null;
                in
                manifestData.endpointsConfig
              else
                manifestData.endpointsConfig manifestData.endpoints
            else
              null;

          # firewallModule: custom or auto-generated
          firewallModule =
            if manifestData.firewall != null then
              manifestData.firewall
            else if manifestData.endpoints != { } then
              # Auto-generate firewall from endpoints
              { lib, self, ... }:
              let
                endpointData = builtins.removeAttrs manifestData.endpoints [ "impl" ];
                ports = lib.mapAttrsToList (_: ep: ep.port) endpointData |> lib.unique;
              in
              {
                imports = [
                  (self.serviceModules.ssl-proxy.srvLib.mkBackboneInnerFirewallRules {
                    inherit lib ports;
                  })
                ];
              }
            else
              null;

          # observabilityImpls: only local concerns (metrics, logging, probes)
          # NOT alerts - that's a remote concern evaluated on grafana/prometheus hosts

          # Collect all metrics exporter implementations (optional, may be empty attrset)
          metricsImpls =
            manifestData.observability.metrics
            |> lib.mapAttrsToList (_: exporter: exporter.impl or null)
            |> lib.filter (impl: impl != null);

          observabilityImpls = lib.flatten [
            metricsImpls
            (lib.optional (
              manifestData.observability.logging.impl or null != null
            ) manifestData.observability.logging.impl)
            (lib.optional (
              manifestData.observability.probes.impl or null != null
            ) manifestData.observability.probes.impl)
          ];

          # Auto-generate firewall rules for metrics endpoints (infrastructure concern)
          # Metrics are always scraped by prometheus from backbone-inner, regardless of
          # custom service firewall rules.
          metricsFirewallModule =
            if manifestData.observability.metrics != { } then
              (
                { lib, self, ... }:
                let
                  # Extract ports from metrics exporters by looking up their endpoint references
                  metricsPorts =
                    lib.mapAttrsToList (
                      exporterName: exporter:
                      let
                        # Determine which endpoint this exporter uses
                        endpointName =
                          if exporter.endpoint != null then
                            exporter.endpoint
                          else
                          # Infer: look for endpoints.metrics first, then fall back to first endpoint
                          if manifestData.endpoints ? metrics then
                            "metrics"
                          else
                            null;
                        endpoint = if endpointName != null then manifestData.endpoints.${endpointName} or null else null;
                      in
                      if endpoint != null then endpoint.port else null
                    ) manifestData.observability.metrics
                    |> lib.filter (p: p != null)
                    |> lib.unique;
                in
                if metricsPorts != [ ] then
                  self.serviceModules.ssl-proxy.srvLib.mkBackboneInnerFirewallRules {
                    inherit lib;
                    ports = metricsPorts;
                  }
                else
                  { }
              )
            else
              null;

          # Auto-assemble backup modules from structured backups config
          backupsModules =
            if manifestData.backups == null then
              [ ]
            else
              let
                bkp = manifestData.backups;
                bkpServiceName = if bkp.serviceName != null then bkp.serviceName else serviceName;
              in
              lib.flatten [
                (lib.localLib.mkBkp {
                  inherit (bkp)
                    paths
                    exclude
                    schedule
                    localDB
                    localOnly
                    ;
                  serviceName = bkpServiceName;
                })
                (lib.optional (bkp.extraConfig != null) (
                  lib.modules.importApply bkp.extraConfig { serviceName = bkpServiceName; }
                ))
              ];

          # storage impl
          extractImpl = attr: if lib.isAttrs attr && attr ? impl then attr.impl else null;

          defaultModules =
            lib.flatten [
              allModules
              endpointsModule
              firewallModule
              metricsFirewallModule
              observabilityImpls
              backupsModules
              (extractImpl (manifestData.storage or { }))
              manifestData.database
            ]
            |> filter (v: v != { } && v != null);

        in
        manifestData
        // {
          # Add auto-assembled default field
          default = defaultModules;

          # Add source tracking for debug
          _sources = {
            inherit hasPublic hasPrivate;
          };
        };

    in
    lib.genAttrs allNames mergeOne;

in
{
  inherit mergeServiceManifests;
}
