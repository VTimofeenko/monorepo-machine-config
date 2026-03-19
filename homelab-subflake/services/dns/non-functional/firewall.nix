{ lib, ... }:
let
  inherit (lib.homelab) getOwnHost getService;

  ownHost = getOwnHost;
  dnsServiceName =
    ownHost.servicesAt
    |> builtins.filter (name: (getService name).moduleName == "dns")
    |> builtins.head;
  dnsService = getService dnsServiceName;

in
{
  # Takes the list of networks the service should access and sets the firewall rules accordingly
  networking.firewall.interfaces =
    dnsService.networkAccess
    |> map (network: ownHost.networks.${network}.adapter or network) # Resolve proper interface name
    |> map (interface: {
      "${interface}".allowedUDPPorts = [ 53 ];
    })
    |> lib.mergeAttrsList;
}
