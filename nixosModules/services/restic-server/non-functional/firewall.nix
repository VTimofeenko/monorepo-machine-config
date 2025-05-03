{ port, ... }:
{ lib, self, ... }:
{
  imports = [
    (self.serviceModules.ssl-proxy.srvLib.mkBackboneInnerFirewallRules {
      inherit lib;
      ports = [ port ];
    })
  ];
  services.restic.server.listenAddress = "${lib.homelab.getOwnIpInNetwork "backbone-inner"}:${port |> toString}";

  # It's the _socket_ that needs to be ordered to start after network is up
  systemd.sockets.restic-rest-server.requires = [ "network-online.target" ];
  systemd.sockets.restic-rest-server.after = [ "network-online.target" ];
}
