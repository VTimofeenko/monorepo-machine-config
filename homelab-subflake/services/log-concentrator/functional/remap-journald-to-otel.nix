/**
    Construct the open telemetry format logs
    https://opentelemetry.io/docs/specs/otel/logs/data-model/

    https://opentelemetry.io/docs/specs/otel/logs/data-model-appendix/#appendix-b-severitynumber-example-mappings

    Output is flat: `ServiceName`/`HostName` at the top, the rest in the
    `ResourceAttributes`/`LogAttributes` maps.

    `ServiceName` is the homelab service owning the unit on that host and
    `homelab.component` says which part of it (main/metrics/backup), see
    `getLogUnitTags`. Unknown units get an empty `ServiceName` and still carry
    `systemd.unit`.
*/
{ lib, ... }:
let
  unitTags = lib.homelab.getLogUnitTags;
in
{
  services.vector.settings.transforms.journald-to-otel-log = {
    type = "remap";
    inputs = [ "vector-log-concentrator" ];
    source =
      # vrl
      ''
        # https://opentelemetry.io/docs/specs/otel/logs/data-model-appendix/#appendix-b-severitynumber-example-mappings
        priority_to_severity_number = {
            "0": 21, # Emergency
            "1": 19, # Alert
            "2": 18, # Critical
            "3": 17, # Error
            "4": 13, # Warning
            "5": 10, # Notice
            "6": 9, # Informational
            "7": 5, # Debug
        }

        # Alternative implementation: nested ifs for ranges, but this will do for now
        severity_number_to_severity_text = {
            "1": "TRACE",
            "5": "DEBUG",
            "9": "INFO",
            "10": "INFO2",
            "13": "WARN",
            "17": "ERROR",
            "18": "ERROR2",
            "19": "ERROR3",
            "21": "FATAL",
        }

        unit_tags = ${builtins.toJSON unitTags}

        severityNumber = get(priority_to_severity_number, [.PRIORITY]) ?? 0
        host = to_string(.host) ?? ""
        unit = to_string(._SYSTEMD_USER_UNIT || ._SYSTEMD_UNIT) ?? ""
        tag = get(unit_tags, [host + "/" + unit]) ?? {}

        . = {
            "Timestamp": format_timestamp!(timestamp(.timestamp) ?? now(), "%+"),
            "ObservedTimestamp": format_timestamp!(now(), "%+"),

            # Journald relies on RFC5424 priorities
            "SeverityText": get(severity_number_to_severity_text, [to_string(severityNumber) ?? ""]) ?? "",
            "SeverityNumber": severityNumber,

            # `get` returns null (not an error) for unknown units; to_string(null) is ""
            "ServiceName": to_string(get(tag, ["service"]) ?? "") ?? "",
            "HostName": host,
            "Body": strip_ansi_escape_codes(.message) ?? .message,
            "ResourceAttributes": compact({
                "systemd.unit": unit,
                "homelab.instance": get(tag, ["instance"]) ?? null,
                "homelab.component": get(tag, ["component"]) ?? null,
            }),
            "LogAttributes": compact({
                "syslog.identifier": .SYSLOG_IDENTIFIER || null,
                "syslog.procid": .PROCID || null,
            }),
        }
      '';
  };

}
