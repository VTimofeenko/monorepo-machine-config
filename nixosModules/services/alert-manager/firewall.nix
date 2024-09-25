{ lib, ... }:
let
  srvName = "alert-manager";
  inherit (lib) pipe;
  inherit (lib.homelab) getService getOwnHost;
in
{
  # Takes the list of networks the service should access and sets the firewall rules accordingly
  networking.firewall.interfaces = pipe (getService srvName) [
    (builtins.getAttr "networkAccess") # -> ["lan" "client"]
    (map (network: getOwnHost.networks.${network}.adapter or network)) # -> ["eth0" "client"]
    (map (interface: {
      name = interface;
      value.allowedTCPPorts = [
        # config.services.prometheus.alertmanager.port
        443
      ];
    }))
    builtins.listToAttrs
  ];
}
