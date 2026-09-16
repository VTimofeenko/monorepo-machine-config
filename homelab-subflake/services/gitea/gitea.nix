{ lib, ... }:
let
  inherit (lib.homelab) getServiceFqdn;

  srvName = "gitea";
  srvFqdn = getServiceFqdn srvName;
in
{
  # Service configuration
  services.gitea = {
    enable = true;
    settings = {
      server = {
        ROOT_URL = "https://${srvFqdn}";
        DOMAIN = srvFqdn;
        START_SSH_SERVER = true;
      };
      session = {
        COOKIE_SECURE = true;
        # Match gitea session life time to keycloak one
        SESSION_LIFE_TIME = 30 * 24 * 60 * 60; # 30 days
      };

      repository = {
        # Allows users to create repos by simply pushing it
        ENABLE_PUSH_CREATE_USER = true;
      };
      # "repository.pull-request" is gitea's own dotted [section] name, not
      # nesting - it must be a sibling key of "repository", not inside it.
      "repository.pull-request" = {
        # My default merge style, works well with bots
        DEFAULT_MERGE_STYLE = "rebase";
      };

      security.ALLOWED_HOST_LIST = "*.${lib.homelab.getSettings.publicDomainName}";
      service = {
        REGISTER_MANUAL_CONFIRM = true;
      };
    };
  };

  # Allow binding on port 22 (privileged port)
  # These settings enable Gitea built-in SSH server to bind to port 22
  systemd.services.gitea.serviceConfig = {
    AmbientCapabilities = lib.mkOverride 10 "CAP_NET_BIND_SERVICE";
    CapabilityBoundingSet = lib.mkOverride 10 "CAP_NET_BIND_SERVICE";
    # TODO: check why/if this is needed. Was it for mail?
    PrivateUsers = lib.mkOverride 10 false;
  };
  imports = [
    ./non-functional/dumps.nix
    ./functional/mailer.nix
  ];
}
