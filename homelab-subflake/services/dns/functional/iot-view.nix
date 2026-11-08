/**
  DNS view for the IoT VLAN. IoT devices cannot leave LAN, so only local zones
  are resolved. Everything else gets 0.0.0.0/:: (same as the blocklist).

  Well-known NTP pools resolve to the local NTP server. Otherwise clients
  never send a packet the gateway could redirect (e.g. Snapmaker U1's chrony
  with `pool pool.ntp.org`).

  Only applies to the DNS instance that has "iot" in `networkAccess`.
*/
{ lib, ... }:
let
  inherit (lib.homelab) getOwnHost getService getNetwork;

  dnsServiceName =
    getOwnHost.servicesAt
    |> builtins.filter (name: (getService name).moduleName == "dns")
    |> builtins.head;

  iotViewName = "iot-vw";
in
{
  config = lib.mkIf (builtins.elem "iot" (getService dnsServiceName).networkAccess) {
    services.unbound.settings.server.access-control-view = [
      "${(getNetwork "iot").prefix} ${iotViewName}"
    ];

    services.unbound.settings.view = [
      ({ name = iotViewName; } // import ../iot-view-zones.nix lib "iot")
    ];
  };
}
