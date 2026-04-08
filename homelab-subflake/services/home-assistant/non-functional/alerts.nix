{ serviceName, ... }:
let
  grafanaDashboardId = "8b2bb3e2-0b78-48c0-9928-47de6cf7e138";
in
{
  Emergency = [
    {
      title = "Scrape is down";
      expr = ''absent(up{resource="srv:${serviceName}"}) or up{resource="srv:${serviceName}"} == 0'';
      description = "Home Assistant metrics are not being scraped. Service may be down.";
    }
  ];
  Warning = [
    {
      title = "High unavailable entity ratio";
      expr = ''count(homeassistant_entity_available{resource="srv:${serviceName}"} == 0) / count(homeassistant_entity_available{resource="srv:${serviceName}"}) > 0.4'';
      description = "More than 40% of Home Assistant entities are unavailable. May indicate widespread device connectivity issues.";
    }
    {
      title = "Low battery sensor";
      expr = ''homeassistant_sensor_battery_percent{resource="srv:${serviceName}"} < 10 and homeassistant_sensor_battery_percent{resource="srv:${serviceName}"} >= 0'';
      description = "A tracked device's battery is below 10%.";
    }
  ];
}
|> builtins.mapAttrs (_: v: v |> map (it: it // { inherit grafanaDashboardId; }))
