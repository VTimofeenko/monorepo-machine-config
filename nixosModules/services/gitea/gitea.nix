{ lib, ... }:
let
  inherit (lib.homelab) getOwnIpInNetwork getServiceFqdn;

  srvName = "gitea";
  srvFqdn = getServiceFqdn srvName;
  ownIP = getOwnIpInNetwork "lan";
in
{
  # Service configuration
  services.gitea = {
    enable = true;
    settings = {
      server = {
        ROOT_URL = "https://${srvFqdn}";
        DOMAIN = srvFqdn;
        SSH_LISTEN_HOST = ownIP;
        START_SSH_SERVER = true;
      };
      session.COOKIE_SECURE = true;

      # Allows users to create repos by simply pushing it
      repository.ENABLE_PUSH_CREATE_USER = true;

      service = {
        REGISTER_MANUAL_CONFIRM = true;
      };

      webhook.ALLOWED_HOST_LIST = "external,${ownIP}";
    };
    # Needed for backups
    dump.enable = true;
  };

  # Setup binds to port 22
  systemd.services.gitea = {
    serviceConfig = {
      # These settings enable gitea built-in server to bind to port 22
      # Source: archwiki
      AmbientCapabilities = "CAP_NET_BIND_SERVICE";
      CapabilityBoundingSet = lib.mkForce "CAP_NET_BIND_SERVICE";
      PrivateUsers = lib.mkForce false;
    };
  };
}
