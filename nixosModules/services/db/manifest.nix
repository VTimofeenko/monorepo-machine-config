let
  serviceName = "db";
in
rec {
  default = [
    module
    ingress.impl
    storage.impl
    backups.impl
    observability.metrics.impl
  ];
  module = ./postgresql.nix;

  ingress = {
    impl = ./non-functional/firewall.nix;
  };

  observability = {
    enable = true;
    metrics = rec {
      enable = true;
      impl = if enable then import ./non-functional/metrics.nix { inherit port; } else { };
      port = 9187;
    };

    logging.enable = false;
  };

  storage.impl = import ./non-functional/storage.nix;
  backups = rec {
    enable = true;
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
}
