/**
  DNS view for the IoT VLAN. IoT devices cannot leave LAN, so only local zones
  are resolved. Everything else gets 0.0.0.0/:: (same as the blocklist).

  Only applies to the DNS instance that has "iot" in `networkAccess`.
*/
{ lib, ... }:
let
  inherit (lib.homelab) getOwnHost getService getNetwork;

  dnsServiceName =
    getOwnHost.servicesAt |> builtins.filter (name: (getService name).moduleName == "dns") |> builtins.head;

  authDnsSrvLib = (lib.homelab.getManifest "auth-dns").srvLib;
  iotViewName = "iot-vw";
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
        );
      }
    ];
  };
}
