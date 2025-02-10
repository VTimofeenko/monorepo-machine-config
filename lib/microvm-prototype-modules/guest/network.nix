{ lib, ... }:
let
  lan = lib.homelab.getNetwork "lan";
in
{
  systemd.network = {
    networks."10-lan" = {
      enable = true;
      name = "10-lan";
      # Default is to match the name of the network
      matchConfig.Name = lib.mkForce "phy-lan";
      networkConfig = {
        DHCP = "no";
        Address = [ "${lib.homelab.getOwnIpInNetwork "lan" |> lib.traceVal }/24" ]; # TODO: remove traceVal
        Gateway = lan.settings.defaultGateway;
        DNS = lan.dnsServers;
        # This will also disable IPv6 assigning
        LinkLocalAddressing = "no";
      };
    };

    links."10-phy-lan" = {
      enable = true;
      linkConfig.Name = "phy-lan";
      matchConfig.PermanentMACAddress = lib.homelab.getOwnHost.networks.lan.macAddr;
    };
  };

  networking.nftables.enable = true;
}
