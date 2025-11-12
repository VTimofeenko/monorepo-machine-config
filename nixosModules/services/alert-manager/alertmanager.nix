{ lib, config, ... }:
let
  srvName = "alert-manager";
  inherit (lib.homelab) getServiceIP getSettings getSrvSecret;
in
{
  age.secrets.alertmanager-tg-key.file = getSrvSecret srvName "telegram-key";
  systemd.services.alertmanager.serviceConfig = {
    LoadCredential = [ "tg-key:${config.age.secrets.alertmanager-tg-key.path}" ];
    Environment = [ "TG_KEY_PATH=%d/tg-key" ];
  };

  services.prometheus.alertmanager = {
    enable = true;
    configuration = {
      route = {
        group_wait = "10s";
        group_interval = "30s";
        repeat_interval = "1h";
        receiver = "telegram";
      };
      receivers = [
        {
          name = "telegram";
          telegram_configs = [
            {
              send_resolved = true;
              bot_token_file = "\${TG_KEY_PATH}";
              chat_id = getSettings.Telegram.Vladimir;
              message =
                let
                  labelsToHide = [
                    "__alert_rule_uid__"
                    "__alert_rule_namespace_uid__"
                    "__name__"
                    "grafana_folder"
                  ];
                  annotationsToHide = [
                    "__dashboardUid__"
                    "__orgId__"
                    "__panelId__"
                    "__value_string__"
                    "__values__"
                  ];
                  concat =
                    list:
                    lib.pipe list [
                      (map (x: "\"${x}\"")) # Encase in quotes
                      toString # Effectively concat with spaces
                    ];
                in
                ''
                  {{ define "conciseAlerts" }}{{ range . }}Labels:
                  {{ range (.Labels.Remove (stringSlice ${concat labelsToHide})).SortedPairs }} - {{ .Name}} = {{ .Value }}
                  {{ end }}Annotations:
                  {{ range (.Annotations.Remove (stringSlice ${concat annotationsToHide})).SortedPairs }} - {{ .Name }} = {{ .Value }}
                  {{ end }}Source: {{ .GeneratorURL }}
                  {{ end }}
                  {{ end }}

                  {{ if gt (len .Alerts.Firing) 0 }}
                  Alerts Firing:
                  {{ template "conciseAlerts" .Alerts.Firing }}
                  {{ end }}
                  {{ if gt (len .Alerts.Resolved) 0 }}
                  Alerts Resolved:
                  {{ template "conciseAlerts" .Alerts.Resolved }}
                  {{ end }}
                '';
            }
          ];
        }
      ];
    };
  };
}
