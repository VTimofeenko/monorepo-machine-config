let
  serviceName = "keycloak";
in
rec {
  default = [
    module
    ingress.impl
    # storage.impl
    backups.impl
  ];
  module = ./keycloak.nix;

  ingress = {
    impl = ./non-functional/firewall.nix;
    sslProxyConfig = ./non-functional/ssl.nix;
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
