/**
  `local-zone`/`local-data` of the IoT view: local zones resolve, well-known
  NTP pools go to the local NTP server, everything else gets 0.0.0.0/::.
  Shared by `functional/iot-view.nix` and per-device views built on top of it.

  `network`: where the clients live, to pick the NTP server address they reach.
*/
lib: network:
let
  inherit (lib.homelab) getService getHostIpInNetwork;

  authDnsSrvLib = (lib.homelab.getManifest "auth-dns").srvLib;

  ntpIP = getHostIpInNetwork (getService "ntp").onHost network;
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
