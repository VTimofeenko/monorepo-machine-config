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

      # Certain IoT clients (cameras) send a minimal DHCP request with an empty client
      # This should prevent `ALLOC_ENGINE_V4_DISCOVER_ADDRESS_CONFLICT` noise in logs
      # and perceived conflicts
      host-reservation-identifiers = [ "hw-address" ];

      lease-database = {
        name = "/var/lib/kea/dhcp4.leases";
        persist = true;
        type = "memfile";
      };
      subnet4 = [
        {
          id = 1;
          pools = [ { pool = "${lan.subnet}.240 - ${lan.subnet}.254"; } ];
          subnet = "${lan.subnet}.0${lan.settings.netmask}";
          # Some clients have weird behavior. If this is omitted, `kea`
          # will think that there are duplicate leases.
          match-client-id = false;

          # Looks like this is needed as an advertisement from DHCP to get gateway to hosts
          option-data = [
            {
              name = "routers";
              data = lan.hostsInNetwork.hydrogen.ipAddress;
            }
          ];
          # Static DHCP assignments
          reservations =
            lan.hostsInNetwork
            |> lib.mapAttrsToList (
              _: hostData: {
                hw-address = hostData.macAddr;
                ip-address = hostData.ipAddress;
                hostname = hostData.fqdn;
              }
            );
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

  # Construct imports from `./functional` directory by auto-including all files
  imports = ./functional |> lib.fileset.fileFilter (file: file.hasExt "nix") |> lib.fileset.toList;
}
