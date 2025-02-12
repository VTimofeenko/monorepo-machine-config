let
  serviceName = "nextcloud";
in
rec {
  # TODO: rework
  default = [
    # module
    ingress.impl
    storage.impl
    ./non-functional/ssl.nix
    ./non-functional/bkp.nix
    backups.impl
  ];
  # module = ./gitea.nix;

  ingress = {
    # impl = ./non-functional/firewall.nix;
    # sslProxyConfig = ./non-functional/ssl.nix; # TODO: move to SSL proxy?
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
    # TODO: remote!
  };
}
