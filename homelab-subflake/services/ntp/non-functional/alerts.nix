{ serviceName, ... }:
let
  grafanaDashboardId = "edwx5l1c1nym8d";
in
{
  # Not an emergency, hosts will survive for a while on their own
  Critical = [
    {
      title = "NTP is down";
      expr = "up{resource=\"srv:${serviceName}\"} == 0";
    }
    {
      title = "NTP is not synchronized";
      expr = "ntp_system_leap_indicator == 3";
      description = "Leap indicator is 3 (alarm/unsync)";
    }
  ];
  Warning = [
    {
      title = "High NTP offset";
      expr = "abs(ntp_source_offset_seconds) > 0.05";
    }
    {
      title = "High NTP send error rate";
      expr = "rate(ntp_server_response_send_errors_total[5m]) > 0";
    }
    {
      title = "System clock is stepping";
      expr = "rate(ntp_system_accumulated_steps_seconds[5m]) > 0";
    }
  ];
}
|> builtins.mapAttrs (_: v: v |> map (it: it // { inherit grafanaDashboardId; }))
