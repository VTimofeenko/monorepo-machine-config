let
  serviceName = "ntfy-sh";
in
rec {
  default = [
    module
    ingress.impl
    # backups.impl
  ];
  module = ./ntfy-sh.nix;

  ingress = rec {
    port = 8004;
    impl = import ./non-functional/firewall.nix { inherit port; };
    sslProxyConfig = import ./non-functional/ssl.nix { inherit port serviceName; };
  };

  monitoring = false;
  logging = false;
  storage = false;
  backups = rec {
    enable = false;
    schedule = "daily";
    paths = [ ];
    impl =
      if enable then import ./non-functional/backups.nix { inherit paths schedule serviceName; } else { };
  };
  dashboard = {
    category = "Dev";
    links = [
      {
        description = "Local notifications";
        icon = "ntfy";
        name = "Ntfy";
      }
    ];
  };
}
