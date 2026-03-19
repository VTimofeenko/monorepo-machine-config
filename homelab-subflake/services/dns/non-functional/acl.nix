/**
  Configures which clients have access to the DNS service.
  Updated to work with multi-instance DNS services.
*/
{ lib, ... }:
let
  inherit (lib.homelab) getServiceConfig getNetwork getOwnHost getService;

  ownHost = getOwnHost;
  dnsServiceName =
    ownHost.servicesAt
    |> builtins.filter (name: (getService name).moduleName == "dns")
    |> builtins.head;
  dnsService = getService dnsServiceName;

  # Get service config using the actual instance name, not module name
  thisSrvConfig = getServiceConfig dnsServiceName;
in
{
  services.unbound.settings.server.access-control =
    # Allow access to clients coming in from default interfaces
    (
      dnsService.networkAccess
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
