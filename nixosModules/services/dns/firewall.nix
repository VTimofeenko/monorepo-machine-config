# TODO: Add generic "allow all 53" back; check impact on DNS performance. Probably neglibible.
{ lib, config, ... }:
{
  # Takes the list of networks the service should access and sets the firewall rules accordingly
  networking.firewall.interfaces = lib.pipe (lib.homelab.getService "dns") [
    (builtins.getAttr "networkAccess") # -> ["lan" "client"]
    (map (
      network: (lib.homelab.getHost config.networking.hostName).networks.${network}.adapter or network
    )) # -> ["eth0" "client"]
    (map (interface: {
      name = interface;
      value = {
        allowedUDPPorts = [ 53 ];
      };
    }))
    builtins.listToAttrs
  ];
}
