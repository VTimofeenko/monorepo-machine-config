let
  serviceName = "homebox";
in
rec {
  default = [
    module
    ingress.impl
    backups.impl
  ];
  module = ./homebox.nix;

  ingress = {
    impl = ./non-functional/firewall.nix;
    sslProxyConfig = ./non-functional/ssl.nix;
  };

  # TODO: implement
  monitoring = false;
  # TODO: implement
  logging = false;
  backups = rec {
    enable = true;
    schedule = "daily";
    paths = [ "/var/lib/homebox/data" ];
    impl =
      if enable then
        { lib, ... }:
        lib.localLib.mkBkp {
          inherit paths serviceName;
        }
      else
        { };
    # TODO: remote!
  };
  dashboard = {
    category = "Home";
    links = [
      {
        description = "Stuff @ home";
        icon = "homebox";
        name = "Homebox";
      }
    ];
  };

  storage = false;
}
