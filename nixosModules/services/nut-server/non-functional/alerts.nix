{ serviceName, ... }:
{
  Emergency = [
    {
      title = "UPS check is down";
      query = "up{job=\"${serviceName}-srv-scrape\"}";
    }
    {
      title = "UPS is on battery";
      query = "network_ups_tools_ups_status{flag=\"OB\"} > 0";
      addVector = true;
    }
    {
      title = "battery needs replacement";
      query = "network_ups_tools_ups_status{flag=\"RB\"} > 0";
      addVector = true;
    }
    {
      title = "low remaining runtime";
      query = "network_ups_tools_battery_runtime < 300";
      addVector = true;
    }
  ];
}
