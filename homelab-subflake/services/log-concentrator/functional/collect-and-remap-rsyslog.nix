/**
  Sets up `rsyslog` collecting and remapping for certain non-NixOS resources.
*/
{ lib, ... }:
{
  options.homelab.services.log-concentrator.rsyslogClients = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Hostnames of clients allowed to send rsyslog events";
  };
  config = {
    # Allow clients
    homelab.services.log-concentrator.rsyslogClients = [
      "nas"
      "ruckus-office"
    ];

    services.vector.settings = {
      api.enabled = true;

      sources.syslog-log-concentrator = {
        type = "syslog";
        mode = "udp";
        address = "0.0.0.0:${
          (lib.homelab.getManifest "log-concentrator").endpoints.syslog.port |> toString
        }"; # Listen on all interfaces, let firewall handle the access
      };

      transforms.syslog-to-otel-log = {
        type = "remap";
        inputs = [ "syslog-log-concentrator" ];
        source =
          # vrl
          ''
            # vector's syslog source emits RFC5424 keywords
            syslog_severity_to_severity_number = {
                "emerg": 21,
                "alert": 19,
                "crit": 18,
                "err": 17,
                "warning": 13,
                "notice": 10,
                "info": 9,
                "debug": 5,
            }
            hostname = if (.host == "ZD-APMgr" || ."source_ip" == "${lib.homelab.hosts.getLANIP "ruckus-office"}") { "ruckus-office" } else {.host}


            . = {
                "Timestamp": format_timestamp!(timestamp(.timestamp) ?? now(), "%+"),
                "ObservedTimestamp": format_timestamp!(now(), "%+"),

                "SeverityText": upcase(to_string(.severity) ?? ""),
                "SeverityNumber": get(syslog_severity_to_severity_number, [to_string(.severity) ?? ""]) ?? 0,

                # Non-NixOS devices: no homelab service
                "ServiceName": "",
                "HostName": hostname,
                "Body": strip_ansi_escape_codes(.message) ?? .message,
                "ResourceAttributes": compact({
                    "syslog.appname": ."app-name" || null,
                    "source.ip": .source_ip || null,
                }),
                "LogAttributes": compact({
                    "syslog.facility": .facility || null,
                    "syslog.version": to_string(.version) ?? null,
                    "syslog.procid": to_string(.procid) ?? null,
                }),
            }
          '';
      };
    };
  };
}
