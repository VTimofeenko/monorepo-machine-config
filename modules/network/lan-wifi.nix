{ lib, ... }:
let
  inherit (lib.homelab)
    getNetwork
    getOwnIpInNetwork
    getService
    getHostIpInNetwork
    ;
  lan = getNetwork "lan";

  ownIP = getOwnIpInNetwork "lan";

  cctv = getNetwork "cctv";

  cctvRouterIP = lib.pipe (getService "cctv-router") [
    (builtins.getAttr "onHost") # -> "uranium"
    (lib.flip getHostIpInNetwork "lan")
  ];
in
{
  networking = {
    # Disable autogenerated names
    usePredictableInterfaceNames = false;
    # Systemd-networkd enabled
    useNetworkd = true;
    defaultGateway.interface = "wifi-lan";
  };

  systemd.network.networks = {
    "10-wifi-lan" = {
      enable = true;
      name = "wifi-lan";
      dns = lan.dnsServers;
      # Search domain goes here
      domains = [ lan.domain ];
      routes = [
        {
          Gateway = cctvRouterIP;
          Destination = cctv.prefix;
        }
      ];
      networkConfig = {
        Address = [ "${ownIP}${lan.settings.netmask}" ];
        Gateway = lan.settings.defaultGateway;
        DHCP = "no";
        DNSSEC = "yes";
        DNSOverTLS = "no";
        # Disable ipv6 explicitly
        LinkLocalAddressing = "no";
      };
    };
  };
  # I am not using llmnr in my LAN
  services.resolved.llmnr = "false";

  # Any interface being up should be OK
  systemd.network.wait-online.anyInterface = true;
}
