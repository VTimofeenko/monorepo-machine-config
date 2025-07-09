/**
    Construct the open telemetry format logs
    https://opentelemetry.io/docs/specs/otel/logs/data-model/

    https://opentelemetry.io/docs/specs/otel/logs/data-model-appendix/#appendix-b-severitynumber-example-mappings
*/
{
  services.vector.settings.transforms.journald-to-otel-log = {
    type = "remap";
    inputs = [ "vector-log-concentrator" ];
    source =
      # vrl
      ''
        # Construct the otel format logs
        # https://opentelemetry.io/docs/specs/otel/logs/data-model/

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

        severityNumber = get(priority_to_severity_number, [.PRIORITY]) ?? null

        . = {
            "Timestamp": to_unix_timestamp(.timestamp) ?? null,
            "ObservedTimestamp": to_unix_timestamp(now()),
            # These don't really map to journald
            "TraceID": null,
            "SpanId": null,

            # Simple mapper of severities
            # Journald relies on RFC5424 priorities
            "SeverityText": get(severity_number_to_severity_text, [to_string(severityNumber) ?? null]) ?? null,
            "SeverityNumber": severityNumber,

            "Body": strip_ansi_escape_codes(.message) ?? .message,
            "Resource": {
                "host": {
                    "name": .host,
                },
                "service": {
                    "name": ._SYSTEMD_USER_UNIT || ._SYSTEMD_UNIT,
                },
            },
            "Attributes": {
                "syslog": {
                    "version": .VERSION || null,
                    "facility": .SYSLOG_IDENTIFIER || null,
                    "procid": .PROCID || null,
                },
            },
        }

      '';
  };

}
