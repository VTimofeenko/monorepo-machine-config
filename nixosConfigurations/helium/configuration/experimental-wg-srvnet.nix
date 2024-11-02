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
          # configuration since nixos-unstable/nixos-24.11
          # {
          #   PublicKey = "L4msD0mEG2ctKDtaMJW2y3cs1fT2LBRVV7iVlWZ2nZc=";
          #   AllowedIPs = [ "10.100.0.2" ];
          # }
          # configuration for nixos 24.05
          {
            wireguardPeerConfig = {
              PublicKey = "bWhybBMzKIZ2UibkW6i8tz/RzL0CVlmO7Jrt9s/apXc=";
              AllowedIPs = [ "10.100.0.2" ]; # 2 for now, this is service, not the host
            };
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
