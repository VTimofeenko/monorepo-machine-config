let
  serviceName = "nextcloud";
in
rec {
  default = [
    module
    # storage.impl
    ingress.impl
    backups.impl
  ];
  module = ./. + "/${serviceName}.nix";

  ingress =
    let
      port = 80;
    in
    {
      impl = import ./non-functional/firewall.nix { inherit port serviceName; };
      sslProxyConfig = import ./non-functional/ssl.nix { inherit port serviceName; };
    };

  # TODO: implement
  monitoring = false;
  # TODO: implement
  logging = false;
  # TODO: refactor
  storage = false;
  backups = rec {
    enable = true;
    paths = [ "/var/lib/nextcloud" ];
    exclude = [ "appdata_ochcggcdayyl/preview" ];
    impl =
      if enable then { lib, ... }: lib.localLib.mkBkp { inherit paths exclude serviceName; } else { };
  };

  dashboard = {
    category = "Home";
    links = [
      {
        icon = "nextcloud";
        name = "Nextcloud";
      }
    ];
  };
}
