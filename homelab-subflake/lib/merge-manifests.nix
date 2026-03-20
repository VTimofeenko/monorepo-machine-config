# Merges public and private service manifests using NixOS module system

{ lib }:
let
  inherit (builtins) trace filter;

  manifestOptionsModule = import ./manifest-options.nix;

  # Takes unevaluated manifest modules and returns evaluated attrset
  mergeServiceManifests = publicServices: privateServices:
    let
      allNames = lib.unique (
        builtins.attrNames publicServices ++ builtins.attrNames privateServices
      );

      mergeOne = serviceName:
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
          allModules = if manifestData.module == null then [] else lib.toList manifestData.module;

          # endpointsModule: custom impl if provided
          endpointsModule =
            if manifestData.endpointsConfig != null then
              manifestData.endpointsConfig manifestData.endpoints
            else
              null;

          # firewallModule: custom or auto-generated
          firewallModule =
            if manifestData.firewall != null then
              manifestData.firewall
            else if manifestData.endpoints != {} then
              # Auto-generate firewall from endpoints
              { lib, self, ... }:
              let
                endpointData = builtins.removeAttrs manifestData.endpoints ["impl"];
                ports = lib.mapAttrsToList (_: ep: ep.port) endpointData
                  |> lib.unique;
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
            (lib.optional (manifestData.observability.logging.impl or null != null)
              manifestData.observability.logging.impl)
            (lib.optional (manifestData.observability.probes.impl or null != null)
              manifestData.observability.probes.impl)
          ];

          # backups and storage impls
          extractImpl = attr: if lib.isAttrs attr && attr ? impl then attr.impl else null;

          defaultModules = lib.flatten [
            allModules
            (lib.optional (endpointsModule != null) endpointsModule)
            (lib.optional (firewallModule != null) firewallModule)
            observabilityImpls
            (lib.optional (extractImpl (manifestData.backups or {}) != null)
              (extractImpl manifestData.backups))
            (lib.optional (extractImpl (manifestData.storage or {}) != null)
              (extractImpl manifestData.storage))
            (lib.optional (manifestData.database != null) manifestData.database)
          ]
          |> filter (v: v != {} && v != null);

        in
        manifestData // {
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
