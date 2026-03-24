/**
  One service currently has a backbone-inner domain name. I will need to
  remove this post-migration, but will leave in for now so nothing is broken.
*/

{ lib, ... }:
let
  inherit (lib.homelab.getManifest "auth-dns") srvLib;
  srv = lib.homelab.getService "log-concentrator";
in
{
  services.nsd.zones.${"backbone-inner" |> lib.homelab.getNetwork |> builtins.getAttr "domain"}.data =
    srvLib.mkARecord (srv |> builtins.getAttr "domain") (
      srv |> builtins.getAttr "onHost" |> lib.flip lib.homelab.getHostIpInNetwork "backbone-inner"
    )
    |> lib.mkAfter;
}
