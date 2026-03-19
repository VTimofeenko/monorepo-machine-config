/**
  Generates DNS records for the backbone-inner.<publicDomain> zone.

  Creates A records for all hosts with backbone-inner network interfaces.
*/
{ lib, ... }:
let
  inherit (lib.homelab.getSettings) publicDomainName;
  netName = "backbone-inner";
  zoneDomain = "backbone-inner.${publicDomainName}";
in
{
  services.nsd.zones.${zoneDomain}.data = lib.mkBefore (
    lib.homelab.services.getByNetworkName netName
    |> lib.mapAttrs' (name: value: lib.nameValuePair name (lib.homelab.services.getInnerIP name))
    |> lib.attrsToList
    |> map (it: "${it.name} IN A ${it.value}")
    |> lib.concatLines
    |> (it: it + "\n") # Zone needs an extra newline at the end
  );
}
