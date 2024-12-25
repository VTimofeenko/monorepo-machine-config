/**
  Source: https://wiki.nixos.org/wiki/WireGuard#Setting_up_WireGuard_with_systemd-networkd
*/
let
  listenPort = 51830;
in
{
  networking.firewall.allowedUDPPorts = [ listenPort ];
  networking.useNetworkd = true;
  systemd.network = {
    enable = true;
    netdevs = {
      "50-srvnet" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "srvnet";
          MTUBytes = "1300";
        };
        wireguardConfig = {
          PrivateKeyFile = "/run/keys/wireguard-privkey";
          ListenPort = listenPort;
        };
        wireguardPeers = [
          {
            PublicKey = "bWhybBMzKIZ2UibkW6i8tz/RzL0CVlmO7Jrt9s/apXc=";
            AllowedIPs = [ "10.100.0.2" ];
          }
        ];
      };
    };
    networks.srvnet = {
      matchConfig.Name = "srvnet";
      address = [ "10.100.0.1/24" ];
      networkConfig = {
        IPMasquerade = "ipv4";
        IPForward = true;
      };
    };
  };
}
