{ serviceName, ... }:
let
  grafanaDashboardId = "fdydurfmfkbuod";
in
{
  Emergency = [
    {
      title = "UPS check is down";
      expr = ''absent(up{resource="srv:${serviceName}"}) or up{resource="srv:${serviceName}"} == 0'';
    }
    {
      title = "UPS is on battery";
      expr = ''network_ups_tools_ups_status{resource="srv:${serviceName}",flag="OB"} > 0'';
    }
    {
      title = "Battery needs replacement";
      expr = ''network_ups_tools_ups_status{resource="srv:${serviceName}",flag="RB"} > 0'';
    }
    {
      title = "Low remaining runtime";
      expr = ''network_ups_tools_battery_runtime{resource="srv:${serviceName}"} < network_ups_tools_battery_runtime_low{resource="srv:${serviceName}"}'';
    }
  ];
  Warning = [
    {
      title = "Low battery charge";
      expr = ''network_ups_tools_battery_charge{resource="srv:${serviceName}"} < 30'';
      description = "Battery charge below 30%";
    }
  ];
}
|> builtins.mapAttrs (_: v: v |> map (it: it // { inherit grafanaDashboardId; }))
