let
  serviceName = "keycloak";
in
rec {
  # TODO: rework
  default = [
    module
    ingress.impl
    storage.impl
    ./non-functional/ssl.nix
    ./non-functional/bkp.nix
    backups.impl
  ];
  module = ./gitea.nix;

  ingress = {
    impl = ./non-functional/firewall.nix;
    # sslProxyConfig = ./non-functional/ssl.nix; # TODO: move to SSL proxy?
  };

  # TODO: implement
  monitoring = false;
  # TODO: implement
  logging = false;
  storage = false;
  backups = rec {
    enable = true;
    # The paths are calculated dynamically here
    paths = [ ];
    impl =
      if enable then
        { lib, ... }:
        lib.localLib.mkBkp {
          inherit paths serviceName;
          localDB = true;
        }
      else
        { };
    # TODO: remote!
  };

  dashboard = {
    category = "Admin";
    links = [
      {
        description = "SSO";
        icon = "keycloak";
        name = "Keycloak";
      }
    ];
  };
}
