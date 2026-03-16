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
}
