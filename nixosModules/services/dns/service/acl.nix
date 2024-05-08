# Module that configures Unbound for recursive DNS, DNSSEC and caching
{ config, ... }:
let
  inherit (config) my-data;

  lan = my-data.lib.getNetwork "lan";
  client = my-data.lib.getNetwork "client";
in
{
  services.unbound.settings.server.access-control =
    (map (x: "${x.prefix} allow") [
      lan
      client
    ])
    ++ [ "${lan.hostsInNetwork.meross-outlet-1.ipAddress}/32 deny" ]; # TODO: maybe move this to a setting?
}
