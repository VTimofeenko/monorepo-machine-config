/**
  This zone contains HOSTs that are in the LAN.
*/
{
  lib,
  ...
}:
let
  zone = (lib.homelab.getNetwork "lan").domain;
  inherit (lib.homelab.getManifest "auth-dns") srvLib;
in
{
  services.nsd.zones.${zone}.data =
    (lib.homelab.getNetwork "lan").hostsInNetwork
    |> lib.mapAttrsToList (_: v: { inherit (v) hostName ipAddress; })
    |> map ({ hostName, ipAddress }: srvLib.mkARecord hostName ipAddress)
    |> lib.concatStringsSep "\n";
}
