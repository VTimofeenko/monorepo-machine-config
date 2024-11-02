{
  containers.sample = {
    autoStart = true;
    privateNetwork = true;
    interfaces = [ "srvnet" ];
    config =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {

        services.nginx = {
          enable = true;
          virtualHosts.localhost = {
            locations."/" = {
              return = "200 '<html><body>It works</body></html>'";
              extraConfig = ''
                default_type text/html;
              '';
            };
          };
        };

        system.stateVersion = "24.05";

        networking = {
          firewall = {
            enable = true;
            allowedTCPPorts = [
              80
              443
            ];
          };
          # Use systemd-resolved inside the container
          # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
          useHostResolvConf = lib.mkForce false;
        };

        services.resolved.enable = true;
        imports = [ ./experimental-wg-srvnet.nix ];
        systemd.network.netdevs."10-srvnet".wireguardPeers = lib.mkForce [
          {
            wireguardPeerConfig = {
              PublicKey = "LFQNLuxjer5pYglPCjcHrWjftRWZtlqLOvQaOgug1Hs=";
              AllowedIPs = [
                "0.0.0.0/0"
              ];
              Endpoint = "192.168.1.2:51830";
              PersistentKeepalive = 5;
            };
          }
        ];

        environment.systemPackages = [
          pkgs.inetutils
          pkgs.nftables
          pkgs.iptables
          pkgs.wireguard-tools
        ];

      };
  };
}
