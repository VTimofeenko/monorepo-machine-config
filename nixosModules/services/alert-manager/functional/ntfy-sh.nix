{ lib, ... }:
let
  address = "127.0.0.1:8000";
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
          # I don't generally want notifications to ring here
          priority = "default";
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
          };
        };
      };
    };
  };
}
