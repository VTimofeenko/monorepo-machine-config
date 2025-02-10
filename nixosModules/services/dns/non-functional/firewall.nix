{ lib, config, ... }:
{
  # Takes the list of networks the service should access and sets the firewall rules accordingly
  networking.firewall.interfaces =
    (lib.homelab.getService "dns")
    |> builtins.getAttr "networkAccess" # -> [ "lan" "client" ]
    |> map (it: (lib.homelab.getHost config.networking.hostName).networks.${it}.adapter or it) # Resolve proper interface name
    |> map (it: {
      "${it}".allowedUDPPorts = [ 53 ];
    })
    |> lib.mergeAttrsList;
}
