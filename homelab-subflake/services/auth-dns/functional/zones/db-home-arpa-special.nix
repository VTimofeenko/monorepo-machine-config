/**
  Some special rules for the DB network
*/
{ lib, ... }:
let
  inherit (lib.homelab.getManifest "auth-dns") srvLib;
  srv = lib.homelab.getService "db";
in
{
  services.nsd.zones.${"db" |> lib.homelab.getNetwork |> builtins.getAttr "domain"}.data =
    srvLib.mkARecord (srv |> builtins.getAttr "domain")
      (srv |> builtins.getAttr "onHost" |> lib.flip lib.homelab.getHostIpInNetwork "db") |> lib.mkAfter;
}
