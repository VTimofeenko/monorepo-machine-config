{ lib, ... }:
rec {
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

  severityNumMap = {
    Emergency = 21;
    Alert = 19;
    Critical = 18;
    Error = 17;
    Warning = 13;
    Notice = 10;
    Informational = 9;
    Debug = 5;
  };

  alertLevels = [
    "Emergency"
    "Alert"
    "Critical"
    "Error"
    "Warning"
    "Notice"
    "Informational"
    "Debug"
  ];

  # Reverse `severityNumMap`:
  numToLevel = severityNumMap |> lib.mapAttrs' (n: v: lib.nameValuePair (toString v) n);

  /**
    Build a single Prometheus alerting rule attrset.

    - `resourceName` — service name (string) or `null` for host-level rules. When
    found in `lib.homelab.services.getAll`, adds `resource = "srv:<name>"` and
    `service` labels automatically.
    - `rule` — attrset with `title`, `expr`, and optionally `for`, `description`,
    `grafanaDashboardId`.
  */
  mkRule =
    resourceName: alertLevel: rule:
    assert lib.assertOneOf "alertLevel" alertLevel alertLevels;
    let
      isService = lib.isString resourceName && lib.homelab.services.getInstances resourceName != [ ];
      isHost = lib.isString resourceName && builtins.hasAttr resourceName lib.homelab.hosts.getAll;
      grafanaFqdn = lib.homelab.getServiceFqdn "grafana";
    in
    lib.warnIf (lib.isString resourceName && !isService && !isHost)
      "mkRule: '${resourceName}' is neither a known service nor a known host"
      {
        alert = rule.title |> lib.splitString " " |> map lib.localLib.uppercase |> lib.concatStrings;
        expr = rule.expr;
        for = rule.for or forDefaults.${alertLevel};
        labels = {
          inherit alertLevel;
          _alertLevelNum = severityNumMap.${alertLevel} |> toString;
        }
        // lib.optionalAttrs isService {
          resource = "srv:${resourceName}";
          service = resourceName;
        }
        // lib.optionalAttrs isHost {
          host = resourceName;
          resource = "host:${resourceName}";
        };
        annotations = {
          summary = rule.title;
        }
        // lib.optionalAttrs (rule ? description) { inherit (rule) description; }
        // lib.optionalAttrs (rule ? grafanaDashboardId) {
          dashboard = "https://${grafanaFqdn}/d/${rule.grafanaDashboardId}";
        };
      };

  /**
    Produce a standard firewall rule that allows Prometheus to scrape metrics.

    TODO: allow comments
  */
  mkBackboneInnerFirewallRules =
    {
      lib,
      ports ? null,
      port ? null,
    }:
    let
      ports' =
        assert lib.assertMsg (lib.xor (isNull ports) (
          isNull port
        )) "`ports` and `port` cannot be specified together, but one of them must be specified.";
        if !isNull ports then ports else port |> lib.toList;
    in
    {
      # The validation is done by nftables, no need to make an extra check
      networking.firewall.extraInputRules =
        ports'
        # Turn into list just in case, so callers don't need to bother.
        |> lib.toList
        # Parse ports coming in as just int. If so – reconstruct attrset.
        # Else leave the value be and let if fail later if needed.
        |> map (
          it:
          if lib.isInt it then
            {
              port = it;
              protocol = "tcp";
            }
          else
            it
        )
        # Construct the firewall rules
        |> map (
          it:
          [
            ''iifname "backbone-inner"''
            "ip saddr { ${"prometheus" |> lib.homelab.getServiceInnerIP} }"
            "${it.protocol} dport ${it.port |> toString} accept"
          ]
          |> builtins.concatStringsSep " "
        )
        |> lib.concatLines;
    };
}
