/**
  Produces a zone for the backbone-inner network.

  This will be used later as the blueprint for nix-managed DNS record generation
*/
{ lib, ... }:
let
  netName = "backbone-inner";
in
{
  services.nsd.zones.${lib.homelab.getNetwork netName |> lib.getAttr "domain"}.data =
    lib.homelab.services.getByNetworkName netName
    |> lib.mapAttrs' (name: value: lib.nameValuePair name (lib.homelab.services.getInnerIP name))
    |> lib.attrsToList
    |> map (it: "${it.name} IN A ${it.value}")
    |> lib.concatLines
    |> (it: it + "\n") # Zone needs an extra newline at the end
  ;
}
