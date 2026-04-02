/**
  Set up `alertmanager-ntfy` to send `Alertmanager` alerts to `ntfy-sh` instance.

  Docs:
  https://github.com/alexbakker/alertmanager-ntfy
*/
{ lib, ... }:
let
  address = "127.0.0.1:8000";
  settings.priorityCutoff = (lib.homelab.getSrvLib "grafana").constants.severityNumMap.Error;
in
{
  services.prometheus.alertmanager-ntfy = {
    enable = true;
    settings = {
      http.addr = address;
      ntfy = {
        baseurl = "https://${lib.homelab.getServiceFqdn "ntfy-sh"}";
        notification = {
          topic = "homelab-alerts";
          priority = ''
            labels._alertLevelNum > ${toString settings.priorityCutoff} ? "default" : "low"
          '';
          tags = [
            {
              tag = "+1";
              condition = ''status == "resolved"'';
            }
            {
              tag = "rotating_light";
              condition = ''status == "firing"'';
            }
          ];
          templates = {
            title = ''{{ if eq .Status "resolved" }}Resolved: {{ end }}{{ index .Annotations "summary" }}'';
            description = ''{{ index .Annotations "description" }}'';
            headers.X-Click = "{{ .GeneratorURL }}";
          };
        };
      };
    };
  };
}
