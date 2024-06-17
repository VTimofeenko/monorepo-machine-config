# Module that configures Unbound for recursive DNS, DNSSEC and caching
{ lib, ... }:
let
  inherit (lib.homelab) getServiceConfig getNetwork;
  thisSrvConfig = getServiceConfig "dns";

  lan = getNetwork "lan";
  client = getNetwork "client";
in
{
  services.unbound.settings.server.access-control =
    (map (x: "${x.prefix} allow") [
      lan
      client
    ])
    ++ (map (x: "${lan.hostsInNetwork.${x}.ipAddress}/32 deny") thisSrvConfig.clientsNonGrata);
}
