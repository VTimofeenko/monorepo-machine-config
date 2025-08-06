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
      session.COOKIE_SECURE = true;

      # Allows users to create repos by simply pushing it
      repository.ENABLE_PUSH_CREATE_USER = true;

      service = {
        REGISTER_MANUAL_CONFIRM = true;
      };
    };
  };
  imports = [
    ./non-functional/dumps.nix
  ];
}
