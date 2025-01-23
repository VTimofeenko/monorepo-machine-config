{ config, lib, ... }:
let
  inherit (config) my-data;
  inherit (my-data.networks) lan;
  inherit (my-data.lib.getOwnHostConfig) netInterfaces;

  inherit (netInterfaces)
    wan
    lan-1
    lan-2
    lan-3
    lan-bridge
    ;

  lanIP = (my-data.lib.getOwnHostInNetwork "lan").ipAddress;
in
{
  # Disable autogenerated names
  networking.usePredictableInterfaceNames = false;
  networking.useNetworkd = true;

  # Consider any iface to be up => network is up
  systemd.network.wait-online.anyInterface = true;

  systemd.network = {
    links =
      let
        mkLink = link: {
          name = "0-${link.name}";
          value = {
            matchConfig.PermanentMACAddress = link.macAddr;
            linkConfig.Name = link.name;
          };
        };
      in
      builtins.listToAttrs (
        map mkLink [
          wan
          lan-1
          lan-2
          lan-3
        ]
      );
    networks = {
      "1-bridge-bind" = {
        # Binds the devices to the bridge, needs to go first
        # https://wiki.archlinux.org/title/Systemd-networkd#Bind_Ethernet_to_bridge
        enable = true;
        matchConfig.Name = lib.concatMapStringsSep " " (adapter: adapter.name) [
          lan-1
          lan-2
          lan-3
        ];
        networkConfig = {
          Bridge = lan-bridge.name;
        };
      };
      "10-lan" = {
        # The bridge network
        # https://wiki.archlinux.org/title/Systemd-networkd#Bridge_network
        enable = true;
        inherit (lan-bridge) name;
        matchConfig.Name = lan-bridge.name;
        networkConfig = {
          Address = [ (lanIP + lan.settings.netmask) ];
          DNS = [ lan.dnsServers ];
          DHCP = "no";
          # DNSSEC = "yes";
          # DNSOverTLS = "no";
          LinkLocalAddressing = "no";
        };
      };
      "99-wan" = {
        enable = true;
        inherit (wan) name;
        matchConfig.Name = "${wan.name}";
        networkConfig = {
          DHCP = "yes"; # Enables DHCP Client on this interface
          DNS = [ lan.dnsServers ]; # Disable getting DNS from upstream.
        };
      };
    };
    netdevs.lan.netdevConfig = {
      # The interface itself
      # https://wiki.archlinux.org/title/Systemd-networkd#Bridge_interface
      Kind = "bridge";
      Name = lan-bridge.name;
      # bridge between LAN ports
    };
  };
}
