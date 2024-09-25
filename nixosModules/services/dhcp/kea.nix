{ lib, ... }:
let
  lan = lib.homelab.getNetwork "lan";

  hostConfig = lib.homelab.getOwnHostConfig;

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
          pools = [ { pool = "${lan.subnet}.240 - ${lan.subnet}.254"; } ];
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
            hostname = hostData.fqdn;
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
    };
  };
}
