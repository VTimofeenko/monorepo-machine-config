let
  serviceName = "google-photos-sync";
in
rec {
  default = [
    module
    backups.impl
  ];

  module = ./. + "/${serviceName}.nix";

  backups = rec {
    enable = true;
    schedule = "daily";
    paths = [ "/var/lib/google-photos-sync/data" ];
    impl =
      if enable then { lib, ... }: lib.localLib.mkBkp { inherit paths serviceName; } else { };
  };
  ingress = false;
  monitoring = false;
  logging = false;
  storage = false;
}
