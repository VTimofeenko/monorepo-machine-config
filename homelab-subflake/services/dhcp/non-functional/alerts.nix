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
    {
      title = "Unknown DHCP client";
      # Every LAN discover gets an offer (LAN has a pool). IoT subnet has no pool,
      # so a device without a reservation keeps sending discovers with no offer.
      expr = ''
        sum by (resource) (increase(kea_dhcp4_packets_received_total{resource="srv:${serviceName}", operation="discover"}[15m]))
          - sum by (resource) (increase(kea_dhcp4_packets_sent_total{resource="srv:${serviceName}", operation="offer"}[15m]))
          > 2
      '';
      description = "A device without a reservation is asking for an address. Get its MAC: journalctl -u kea-dhcp4-server | grep ALLOC_FAIL";
    }
  ];
}
|> builtins.mapAttrs (_: v: v |> map (it: it // { inherit grafanaDashboardId; }))
