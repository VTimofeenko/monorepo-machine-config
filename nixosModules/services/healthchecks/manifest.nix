let
  serviceName = "healthchecks";
in
rec {
  default = [
    module
    ingress.impl
    backups.impl
  ];
  module = ./. + "/${serviceName}.nix";
  ingress =
    let
      port = 8000;
    in
    {
      impl = import ./non-functional/firewall.nix { inherit port; };
      sslProxyConfig = import ./non-functional/ssl.nix { inherit port serviceName; };
    };

  monitoring = false; # TODO: implement
  logging = false; # TODO: implement
  storage = false;

  backups = rec {
    enable = false; # FIXME: enable once network is fixed
    paths = [ "/var/lib/healthchecks" ];
    impl = if enable then { lib, ... }: lib.localLib.mkBkp { inherit paths serviceName; localOnly = true; } else { };
  };

  dashboard = {
    category = "Admin";
    links = [
      {
        description = "Periodic ping reporting (backups, network check, etc.)";
        icon = "healthchecks";
        name = "Healthchecks";
      }
    ];
  };
}
