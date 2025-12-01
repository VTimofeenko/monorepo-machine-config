let
  serviceName = "keycloak";
in
rec {
  default = [
    module
    ingress.impl
    # storage.impl
    backups.impl
    observability.metrics.impl
  ];
  module = ./keycloak.nix;

  ingress = {
    impl = ./non-functional/firewall.nix;
    sslProxyConfig = ./non-functional/ssl.nix;
  };

  observability = {
    enable = true;
    metrics = rec {
      enable = true;
      impl = if enable then import ./non-functional/metrics.nix { inherit port; } else { };
      port = 9000;
    };
    alerts = rec {
      enable = true;
      grafanaImpl = if enable then import ./non-functional/alerts.nix { inherit serviceName; } else { };
    };
  };
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
