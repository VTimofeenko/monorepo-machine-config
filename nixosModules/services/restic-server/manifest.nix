let
  serviceName = "restic-server";
in
rec {
  default = [
    module
    ingress.impl
    storage.impl
    monitoring.impl
  ];
  module = ./impl.nix;
  ingress =
    let
      port = 8080;
    in
    {
      impl = import ./non-functional/firewall.nix { inherit port; };
      sslProxyConfig = import ./non-functional/ssl.nix { inherit port serviceName; };
    };

  monitoring = {
    # TODO: implement
    impl = ./non-functional/monitoring.nix;
  };
  logging = false; # TODO: implement
  storage = {
    impl = ./non-functional/storage.nix;
  };
  backups = false;
}
