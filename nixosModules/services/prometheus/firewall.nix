{ lib, config, ... }:
let
  srvName = "prometheus";
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
        config.services.${srvName}.port
        # Checks that the service is on the same host. Prevents misuse of the module
        (
          assert config.services.prometheus.alertmanager.enable;
          config.services.prometheus.alertmanager.port
        )
        443 # FIXME: Temporary
      ];
    }))
    builtins.listToAttrs
  ];
}
