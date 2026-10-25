{ serviceName, ... }:
let
  lowSpoolGrams = 100;
in
{
  Error = [
    {
      title = "Spoolman is down";
      expr = ''absent(up{resource="srv:${serviceName}"}) or up{resource="srv:${serviceName}"} == 0'';
      description = "Spoolman is not responding. Printers cannot report filament usage.";
    }
  ];
  Notice = [
    {
      title = "Spool running low";
      # Spoolman only exports non-archived spools; archive empty ones to clear
      # this. Spools without an initial weight are not covered.
      #
      # Spoolman never drops stale `filament_info` label sets (e.g. after a
      # color/name edit) until restarted; `topk` keeps the join one-to-one so
      # the rule does not error out. A just-renamed filament may show its old
      # name until then.
      expr = ''
        (
          (spoolman_spool_initial_weight{resource="srv:${serviceName}"} - spoolman_spool_weight_used{resource="srv:${serviceName}"})
          < ${toString lowSpoolGrams}
        )
        * on(filament_id) group_left(name, vendor, material)
          topk by (filament_id) (1, spoolman_filament_info{resource="srv:${serviceName}"})
      '';
      description = "Spool #{{ $labels.spool_id }} ({{ $labels.vendor }} {{ $labels.name }}) has {{ $value | printf \"%.0f\" }}g left.";
    }
  ];
}
