{ lib, ... }:
let
  lan = lib.homelab.getNetwork "lan";

  hostConfig = lib.homelab.getOwnHostConfig;

  inherit (hostConfig) netInterfaces;
  inherit (netInterfaces) lan-bridge;

  iot = lib.homelab.getNetwork "iot";
  iotGateway = iot.hostsInNetwork.hydrogen.ipAddress;

  # Static DHCP assignments
  mkReservations =
    net:
    net.hostsInNetwork
    |> lib.mapAttrsToList (
      _: hostData: {
        hw-address = hostData.macAddr;
        ip-address = hostData.ipAddress;
        hostname = hostData.fqdn;
      }
    );
in
{
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [
          # Where to listen on
          lan-bridge.name
          "iot"
        ];
        # Fail loudly instead of silently skipping an interface it could not
        # bind to. Ordering is done in `systemd.services.kea-dhcp4-server`.
        service-sockets-require-all = true;
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
          reservations = mkReservations lan;
        }
        {
          id = 2;
          interface = "iot";
          subnet = iot.prefix;
          # No pools: only reserved hosts get an address. Unknown clients are
          # logged as ALLOC_ENGINE_V4_ALLOC_FAIL_* with their MAC and alerted on.
          pools = [ ];
          match-client-id = false;
          option-data = [
            {
              name = "routers";
              data = iotGateway;
            }
            {
              name = "domain-name-servers";
              data = iotGateway;
            }
            {
              name = "ntp-servers";
              data = iotGateway;
            }
            {
              name = "domain-name";
              data = iot.domain;
            }
            {
              name = "domain-search";
              data = "${iot.domain}, ${lan.domain}";
            }
          ];
          reservations = mkReservations iot;
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

  # network-online is reached with any interface up; wait until the listening
  # interfaces have their addresses, otherwise kea cannot bind to them
  systemd.services.kea-dhcp4-server =
    let
      waitFor = [
        "systemd-networkd-wait-online@${lan-bridge.name}.service"
        "systemd-networkd-wait-online@iot.service"
      ];
    in
    {
      wants = waitFor;
      after = waitFor;
    };

  # Construct imports from `./functional` directory by auto-including all files
  imports = ./functional |> lib.fileset.fileFilter (file: file.hasExt "nix") |> lib.fileset.toList;
}
