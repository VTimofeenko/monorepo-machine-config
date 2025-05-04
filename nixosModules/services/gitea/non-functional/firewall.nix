{ sshPort, webPort, ... }:
{
  lib,
  self,
  ...
}:
let
  settings.listenInterface = "backbone-inner";
in
{
  services.gitea.settings.server = {
    SSH_LISTEN_HOST = lib.homelab.getOwnIpInNetwork settings.listenInterface;
    SSH_PORT = sshPort;
    HTTP_PORT = webPort;
  };

  # Allow binding on port 22
  systemd.services.gitea = {
    serviceConfig = {
      # These settings enable Gitea built-in server to bind to port 22
      # Source: archwiki
      AmbientCapabilities = "CAP_NET_BIND_SERVICE";
      CapabilityBoundingSet = lib.mkForce "CAP_NET_BIND_SERVICE";
      PrivateUsers = lib.mkForce false;
    };
  };

  imports = [
    (self.serviceModules.ssl-proxy.srvLib.mkBackboneInnerFirewallRules {
      inherit lib;
      ports = [
        sshPort
        webPort
      ];
    })
  ];
}
