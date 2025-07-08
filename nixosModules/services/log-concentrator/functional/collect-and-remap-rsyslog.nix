{ lib, ... }:
{
  options.homelab.services.log-concentrator.rsyncClients = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Hostnames of clients allowed to send rsyslog events";
  };
  config = {
    # Allow clients
    homelab.services.log-concentrator.rsyncClients = [
      "nas"
      "ruckus-office"
    ];

    services.vector.settings = {
      api.enabled = true;

      sources.syslog-log-concentrator = {
        type = "syslog";
        mode = "udp";
        address =
          let
            syslogPort = 514;
          in
          "0.0.0.0:${syslogPort |> toString}"; # Listen on all interfaces, let firewall handle the access
      };

      transforms.syslog-to-otel-log = {
        type = "remap";
        inputs = [ "syslog-log-concentrator" ];
        source =
          # vrl
          ''
            severity_text_to_severity_number = {
                "TRACE": "1",
                "DEBUG": "5",
                "INFO": "9",
                "INFO2": "10",
                "WARN": "13",
                "ERROR": "17",
                "ERROR2": "18",
                "ERROR3": "19",
                "FATAL": "21",
            }
            hostname = if (.host == "ZD-APMgr" || ."source_ip" == "${lib.homelab.hosts.getIPInNetwork "lan" "ruckus-office"}") { "ruckus-office" } else {.host}


            . = {
                "Timestamp": to_unix_timestamp(.timestamp) ?? null,
                "ObservedTimestamp": to_unix_timestamp(now()),

                # These don't really map to journald
                "TraceID": null,
                "SpanId": null,

                "SeverityText": .severity,
                "SeverityNumber": get(severity_text_to_severity_number, [to_string(.severity) ?? null]) ?? null,

                "Body": strip_ansi_escape_codes(.message) ?? .message,
                "Resource": {
                    "host": {
                        "name": hostname,
                    },
                    "service": {
                        "name": ."app-name" || null,
                    },
                },
                "Attributes": {
                    "syslog": {
                        "facility": .facility || null,
                        "version": .version || null,
                        "procid": .procid || null,
                    },
                },
            }
          '';
      };
    };
  };
}
