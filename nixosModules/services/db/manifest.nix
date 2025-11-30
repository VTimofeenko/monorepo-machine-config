let
  serviceName = "db";
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
    paths = [ ];
    # Miniflux stores stuff in the local database
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
}
