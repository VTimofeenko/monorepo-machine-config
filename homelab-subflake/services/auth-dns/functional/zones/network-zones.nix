/**
  For all networks, create a zone containing the hosts
*/
{ lib, ... }:

let
  inherit (lib.homelab.getManifest "auth-dns") srvLib;
in
{
  services.nsd.zones =
    [
      "lan"
      "db"
      "mgmt"
      "backbone"
      "backbone-inner"
    ]
    |> map srvLib.mkZoneForNet
    |> lib.mergeAttrsList;
}
