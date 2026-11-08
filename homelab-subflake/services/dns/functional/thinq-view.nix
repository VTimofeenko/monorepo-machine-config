/**
  DNS view for LG ThinQ appliances redirected to `rethink`: `*.lgthinq.com`
  resolves to rethink's host, everything else as in the IoT view.

  One /32 per appliance. `access-control-view` is longest-prefix matched, so
  it wins over the broader views for these devices only.

  Applies to every DNS instance serving "lan" (where the appliances live): DHCP
  hands LAN clients all of them, so each must answer the same.
*/
{ lib, ... }:
let
  inherit (lib.homelab) getOwnHost getService getHostIpInNetwork;

  dnsServiceName =
    getOwnHost.servicesAt
    |> builtins.filter (name: (getService name).moduleName == "dns")
    |> builtins.head;

  inherit ((lib.homelab.getManifest "rethink").srvLib) appliances;
  rethinkIP = getHostIpInNetwork (getService "rethink").onHost "lan";

  viewName = "thinq-vw";
  iotZones = import ../iot-view-zones.nix lib "lan";
in
{
  config = lib.mkIf (builtins.elem "lan" (getService dnsServiceName).networkAccess) {
    services.unbound.settings.server.access-control-view =
      appliances |> map (name: "${getHostIpInNetwork name "lan"}/32 ${viewName}");

    services.unbound.settings.view = [
      {
        name = viewName;
        # AAAA gets NODATA (no AAAA local-data), pinning the appliances to IPv4
        local-zone = iotZones.local-zone ++ [ ''"lgthinq.com" redirect'' ];
        local-data = iotZones.local-data ++ [ ''"lgthinq.com A ${rethinkIP}"'' ];
      }
    ];
  };
}
