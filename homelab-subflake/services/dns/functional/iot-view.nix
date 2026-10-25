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
  inherit (lib.homelab) getOwnHost getService getNetwork getHostIpInNetwork;

  dnsServiceName =
    getOwnHost.servicesAt |> builtins.filter (name: (getService name).moduleName == "dns") |> builtins.head;

  authDnsSrvLib = (lib.homelab.getManifest "auth-dns").srvLib;
  iotViewName = "iot-vw";

  ntpIP = getHostIpInNetwork (getService "ntp").onHost "iot";
  # `redirect` answers the zone and all its subdomains with the zone's data
  ntpZones = [
    "pool.ntp.org"
    "time.google.com"
    "time.cloudflare.com"
    "time.windows.com"
    "time.apple.com"
    "ntp.ubuntu.com"
  ];
in
{
  config = lib.mkIf (builtins.elem "iot" (getService dnsServiceName).networkAccess) {
    services.unbound.settings.server.access-control-view = [
      "${(getNetwork "iot").prefix} ${iotViewName}"
    ];

    services.unbound.settings.view = [
      {
        name = iotViewName;
        local-zone = [
          ''"." always_null''
        ]
        # Local zones are resolved as usual (through the stub/forward zones to NSD)
        ++ (
          authDnsSrvLib.getZones ++ authDnsSrvLib.getReverseZones.reverseZones
          |> map (zone: ''"${zone}" transparent'')
        )
        ++ map (zone: ''"${zone}" redirect'') ntpZones;
        local-data = map (zone: ''"${zone} A ${ntpIP}"'') ntpZones;
      }
    ];
  };
}
