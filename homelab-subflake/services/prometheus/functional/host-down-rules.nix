/**
  Generates per-host "Host Down" alerting rules.

  Severity is derived from the highest alert level of services running on each
  host. Hosts with no alerting services default to Warning.
*/
{ lib, pkgs, ... }:
let
  inherit (lib.homelab.getSrvLib "prometheus") severityNumMap numToLevel;

  defaultHostSeverity = "Warning";

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

  maxSeverityNum =
    alerts:
    alerts |> lib.mapAttrsToList (alertLevel: _: severityNumMap.${alertLevel}) |> lib.foldl' lib.max 0;

  # `host` -> max `_alertLevelNum` across all alerting service instances on that host.
  hostMaxSeverityNum =
    lib.homelab.getManifests
    |> lib.filterAttrs (_: m: m.observability.alerts.prometheusImpl or null != null)
    |> lib.mapAttrsToList (
      modName: manifest:
      let
        num = importAlerts modName manifest.observability.alerts.prometheusImpl |> maxSeverityNum;
      in
      lib.homelab.services.getInstances modName
      |> map (instanceName: {
        host = lib.homelab.getServiceHost instanceName;
        inherit num;
      })
    )
    |> lib.flatten
    |> lib.foldl' (acc: { host, num }: acc // { ${host} = lib.max (acc.${host} or 0) num; }) { };

  mkHostDownRule =
    hostName:
    let
      maxNum = hostMaxSeverityNum.${hostName} or 0;
      level = if maxNum == 0 then defaultHostSeverity else numToLevel.${toString maxNum};
      num = severityNumMap.${level};
    in
    {
      alert = "Host `${hostName}` Down";
      expr = ''up{resource="host:${hostName}"} == 0'';
      for = "2m";
      labels = {
        alertLevel = level;
        _alertLevelNum = toString num;
        host = hostName;
        resource = "host:${hostName}";
      };
      annotations.summary = "${hostName} is unreachable";
    };

in
{
  services.prometheus.ruleFiles = [
    (pkgs.writeText "host-down.rules.json" (
      {
        groups = [
          {
            name = "host-down";
            rules =
              lib.homelab.traits.get "monitoring-source" |> builtins.getAttr "onHosts" |> map mkHostDownRule;
          }
        ];
      }
      |> builtins.toJSON
    ))
  ];
}
