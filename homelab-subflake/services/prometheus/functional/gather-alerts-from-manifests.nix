/**
  Gathers Prometheus alerting rules from service manifests.

  Generates:
  - Per-service rule groups from `observability.alerts.prometheusImpl`
  - Per-host "Host Down" rules with severity derived from the services on each host
*/
{ lib, pkgs, ... }:
let
  inherit (lib.homelab.getSrvLib "prometheus") severityNumMap alertLevels;

  grafanaFqdn = lib.homelab.getServiceFqdn "grafana";

  forDefaults = {
    Emergency = "0m";
    Alert = "2m";
    Critical = "2m";
    Error = "2m";
    Warning = "5m";
    Notice = "5m";
    Informational = "5m";
    Debug = "5m";
  };

  # Import an `alerts.nix` path. Supports both plain attrsets and
  # `{ lib, serviceName, ... }` functions.
  importAlerts =
    srvName: path:
    let
      raw = import path;
    in
    if lib.isFunction raw then
      raw {
        inherit lib;
        serviceName = srvName;
      }
    else
      raw;

  # Build a single Prometheus alerting rule attrset.
  mkRule =
    srvName: alertLevel: rule:
    assert lib.assertOneOf "alertLevel" alertLevel alertLevels;
    {
      alert = rule.title |> lib.splitString " " |> map lib.localLib.uppercase |> lib.concatStrings;
      expr = rule.expr;
      for = rule.for or forDefaults.${alertLevel};
      labels = {
        inherit alertLevel;
        _alertLevelNum = severityNumMap.${alertLevel} |> toString;
        resource = "srv:${srvName}";
        service = srvName;
      };
      annotations = {
        summary = rule.title;
      }
      // lib.optionalAttrs (rule ? description) { inherit (rule) description; }
      // lib.optionalAttrs (rule ? grafanaDashboardId) {
        dashboard = "https://${grafanaFqdn}/d/${rule.grafanaDashboardId}";
      };
    };

  # Expand all alerts from a manifest into a flat list of rule attrsets.
  mkServiceRules =
    srvName: manifest:
    importAlerts srvName manifest.observability.alerts.prometheusImpl
    |> lib.mapAttrsToList (alertLevel: rules: rules |> map (mkRule srvName alertLevel))
    |> lib.flatten;

in
{
  services.prometheus.ruleFiles = [
    (pkgs.writeText "service-alerts.rules.json" (
      lib.homelab.getManifests
      |> lib.filterAttrs (_: m: m.observability.alerts.prometheusImpl or null != null)
      |> lib.mapAttrsToList (
        srvName: manifest: {
          name = srvName;
          rules = mkServiceRules srvName manifest;
        }
      )
      |> (groups: { inherit groups; })
      |> builtins.toJSON
    ))
  ];
}
