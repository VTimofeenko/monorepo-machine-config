{
  services.prometheus.rules = [
    (
      {
        groups = [
          {
            name = "example-group";
            rules = [
              {
                record = "code:prometheus_http_requests_total:sum";
                expr = "sum by (code) (prometheus_http_requests_total)";
                labels._findme = "record-rule";
              }
              {
                alert = "Instance down";
                expr = "up == 0";
                for = "5m";
                labels._findme = "alert-rule";
              }
            ];
          }
        ];
      }
      |> builtins.toJSON
      |> builtins.toString
    )
  ];
}
