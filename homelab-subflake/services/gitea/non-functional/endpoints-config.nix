endpoints: { lib, ... }:
let
  listenInterface = "backbone-inner";
in
{
  services.gitea.settings.server = {
    HTTP_PORT = endpoints.web.port;
    SSH_PORT = endpoints.ssh.port;
    SSH_LISTEN_HOST = lib.homelab.getOwnIpInNetwork listenInterface;
  };

  # Allow binding on port 22
  systemd.services.gitea.serviceConfig = {
    # These settings enable Gitea built-in server to bind to port 22
    # Source: archwiki
    AmbientCapabilities = "CAP_NET_BIND_SERVICE";
    CapabilityBoundingSet = lib.mkForce "CAP_NET_BIND_SERVICE";
    PrivateUsers = lib.mkForce false;
  };
}
