{
  systemd.network = {
    enable = true;
    netdevs = {
      "10-srvnet" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "srvnet";
          MTUBytes = "1300";
        };
        # See also man systemd.netdev (also contains info on the permissions of the key files)
        wireguardConfig = {
          PrivateKeyFile = "/wg";
        };
        wireguardPeers = [
          # configuration since nixos-unstable/nixos-24.11
          # {
          #   PublicKey = "OhApdFoOYnKesRVpnYRqwk3pdM247j8PPVH5K7aIKX0=";
          #   AllowedIPs = [
          #     "fc00::1/64"
          #     "10.100.0.1"
          #   ];
          #   Endpoint = "{set this to the server ip}:51820";
          # }
          # configuration for nixos 24.05
          {
            wireguardPeerConfig = {
              PublicKey = "LFQNLuxjer5pYglPCjcHrWjftRWZtlqLOvQaOgug1Hs=";
              AllowedIPs = [
                "10.100.0.1"
              ];
              Endpoint = "192.168.1.2:51830";
              PersistentKeepalive = 5;
            };
          }
        ];
      };
    };
  };
}
