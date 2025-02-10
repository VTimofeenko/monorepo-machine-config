{ lib, ... }:
let
  port = 8080;
in
{
  services.restic.server.listenAddress = "${lib.homelab.getOwnIpInNetwork "backbone-inner"}:${port |> toString}";

  # It's the _socket_ that needs to be ordered to start after network is up
  systemd.sockets.restic-rest-server.requires = [ "network-online.target" ];
  systemd.sockets.restic-rest-server.after = [ "network-online.target" ];

  networking.firewall.extraInputRules =
    [
      ''ip saddr ${lib.homelab.getHostIpInNetwork "fluorine" "backbone-inner"}'' # TODO: parameterize this as the global SSL proxy
      ''tcp dport ${port |> toString} accept''
    ]
    |> builtins.concatStringsSep " ";
}
