/**
  Generates DNS records for the home.arpa (LAN) zone.

  Auto-generates A records for all LAN devices from network configuration.
*/
{ lib, ... }:
let
  lan = lib.homelab.getNetwork "lan";

  # Generate A records for all LAN hosts
  lanRecords =
    lan.hostsInNetwork
    |> lib.mapAttrsToList (_name: hostData: "${hostData.hostName} IN A ${hostData.ipAddress}")
    |> lib.concatLines
    |> (records: "${records}\n");
in
{
  services.nsd.zones."home.arpa".data = lib.mkBefore lanRecords;
}
