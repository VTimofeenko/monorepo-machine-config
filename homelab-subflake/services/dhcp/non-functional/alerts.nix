{ serviceName, ... }:
let
  grafanaDashboardId = "fdwtdpr213zlsf";
in
{
  Critical = [
    {
      title = "DHCP is down";
      expr = ''up{resource="srv:${serviceName}"} == 0'';
    }
  ];
  Warning = [
    {
      title = "DHCP reservation conflict";
      expr = ''rate(kea_dhcp4_reservation_conflicts_total{resource="srv:${serviceName}"}[5m]) > 0'';
      description = "A dynamic lease was assigned to an address reserved for a different client";
    }
    {
      title = "DHCP packet parse failures";
      expr = ''rate(kea_dhcp4_packets_received_total{resource="srv:${serviceName}", operation="parse-failed"}[5m]) > 0'';
      description = "Kea is receiving malformed DHCP packets";
    }
    {
      title = "DHCP packets being dropped";
      expr = ''rate(kea_dhcp4_packets_received_total{resource="srv:${serviceName}", operation="drop"}[5m]) > 0'';
      description = "Kea is dropping DHCP packets";
    }
  ];
}
|> builtins.mapAttrs (_: v: v |> map (it: it // { inherit grafanaDashboardId; }))
