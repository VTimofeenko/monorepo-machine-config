/**
  Configures which clients have access to the DNS service.
*/
{ lib, ... }:
let
  inherit (lib.homelab) getServiceConfig getNetwork;
  thisSrvConfig = getServiceConfig "dns";
in
{
  services.unbound.settings.server.access-control =
    # Allow access to clients coming in from default interfaces
    (
      (lib.homelab.getService "dns")
      |> builtins.getAttr "networkAccess"
      |> map getNetwork
      |> map (builtins.getAttr "prefix")
      |> map (it: "${it} allow")
    )
    ++
      # Forbid some clients
      (
        thisSrvConfig.clientsNonGrata
        |> map (lib.flip lib.homelab.getHostIpInNetwork "lan")
        |> map (it: "${it}/32 deny")
      );
}
