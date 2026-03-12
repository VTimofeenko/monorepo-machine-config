{ rcvName, chat_id, ... }:
{
  receivers = [
    {
      name = rcvName;
      telegram_configs = [
        {
          send_resolved = true;
          bot_token_file = "\${TG_KEY_PATH}";
          inherit chat_id;
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
                list
                # Encase in quotes
                |> (map (x: "\"${x}\""))
                # Effectively concatenate with spaces
                |> toString;
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

}
