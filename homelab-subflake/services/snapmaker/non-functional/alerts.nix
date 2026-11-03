{ serviceName, ... }:
let
  sel = ''resource="srv:${serviceName}"'';
in
{
  # The printer being off is fine. Losing it with a job in flight is not:
  # `total_duration` advances through the whole job (incl. heat-up, pauses),
  # its last observed step tells whether a job was running when scrapes stopped.
  Alert = [
    {
      title = "Snapmaker offline while printing";
      expr = ''last_over_time(idelta(klipper_print_total_duration{${sel}}[1m])[1h:]) > 0 unless on() up{${sel},exporter="main"} == 1'';
      for = "2m";
    }
  ];
}
