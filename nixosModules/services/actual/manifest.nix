let
  serviceName = "actual";
in
rec {
  default = [
    module
    ingress.impl
    backups.impl
    SSO.impl
  ];
  module = ./. + "/${serviceName}.nix";

  ingress = rec {
    port = 3001;
    impl = import ./non-functional/firewall.nix { inherit port; };
    sslProxyConfig = import ./non-functional/ssl.nix { inherit port serviceName; };
  };

  observability = {
    enable = false;
    alerts = rec {
      enable = true;
      grafanaImpl = if enable then import ./non-functional/alerts.nix { inherit serviceName; } else { };
    };
  };
  backups = rec {
    enable = true;
    schedule = "daily";
    paths = [ "/var/lib/actual" ];
    impl =
      if enable then
        { lib, ... }:
        lib.localLib.mkBkp {
          inherit paths serviceName;
        }
      else
        { };
  };
  dashboard = {
    category = "Home";
    links = [
      {
        description = "Local budgeting";
        icon = "actual-budget";
        name = "Actual Budget";
      }
    ];
  };
  SSO = rec {
    enable = true;
    impl = if enable then import ./non-functional/sso.nix else { };
  };

  storage = false;
}
