{ lib, config, ... }:
let
  inherit (config) my-data;
  # thisSrvConfig = localLib.getSrvConfig "dhcp"; # TODO: add to the main data
  lan = my-data.lib.getNetwork "lan";

  hostConfig = my-data.lib.getOwnHostConfig;

  inherit (hostConfig) netInterfaces;
  inherit (netInterfaces) lan-bridge;
in
{
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [
          # Where to listen on
          lan-bridge.name
        ];
      };
      lease-database = {
        name = "/var/lib/kea/dhcp4.leases";
        persist = true;
        type = "memfile";
      };
      renew-timer = 1000;
      rebind-timer = 2000;
      valid-lifetime = 4000;
      subnet4 = [
        {
          id = 1;
          pools = [ { pool = "${lan.subnet}.2 - ${lan.subnet}.254"; } ];
          subnet = "${lan.subnet}.0${lan.settings.netmask}";

          # Looks like this is needed as an advertisement from DHCP to get gateway to hosts
          option-data = [
            {
              name = "routers";
              data = lan.hostsInNetwork.hydrogen.ipAddress;
            }
          ];
          # Static DHCP assignments
          reservations = lib.attrsets.mapAttrsToList (_: hostData: {
            hw-address = hostData.macAddr;
            ip-address = hostData.ipAddress;
          }) lan.hostsInNetwork;
        }
      ];
      option-data = [
        {
          name = "domain-name-servers";
          data = builtins.concatStringsSep ", " lan.dnsServers;
        }
        {
          name = "domain-name";
          data = lan.domain;
        }
        {
          name = "domain-search";
          data = lan.domain;
        }
      ];
      # TODO: loggers
    };
  };
  # TODO: Firewall
}
