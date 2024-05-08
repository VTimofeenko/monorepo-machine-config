# Module that configures Unbound for recursive DNS, DNSSEC and caching
{ config, ... }:
let
  inherit (config) my-data;
  thisSrvConfig = my-data.lib.getServiceConfig "dns_1"; # FIXME: flaky _1 addressing

  lan = my-data.lib.getNetwork "lan";
  client = my-data.lib.getNetwork "client";
in
{
  services.unbound.settings.server.access-control =
    (map (x: "${x.prefix} allow") [
      lan
      client
    ])
    ++ (map (x: "${lan.hostsInNetwork.${x}.ipAddress}/32 deny") thisSrvConfig.clientsNonGrata);
}
