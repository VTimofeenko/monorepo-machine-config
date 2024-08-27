{ lib, config, ... }:
let
  srvName = "prometheus";
  inherit (lib) pipe;
  inherit (lib.homelab) getService getOwnIpInNetwork getOwnHost;
in
{
  # NOTE: Assumes the name in config.services is the same as module
  services.${srvName}.listenAddress = pipe (getService srvName) [
    (builtins.getAttr "networkAccess")
    lib.head # NOTE: Effectively assumes that the first in list is the needed network
    getOwnIpInNetwork
  ];

  # Takes the list of networks the service should access and sets the firewall rules accordingly
  networking.firewall.interfaces = pipe (getService srvName) [
    (builtins.getAttr "networkAccess") # -> ["lan" "client"]
    (map (network: getOwnHost.networks.${network}.adapter or network)) # -> ["eth0" "client"]
    (map (interface: {
      name = interface;
      value.allowedTCPPorts = [ config.services.${srvName}.port ];
    }))
    builtins.listToAttrs
  ];
}
