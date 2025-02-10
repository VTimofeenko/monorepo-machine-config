rec {
  default = [
    module
    ingress.impl
    storage.impl
  ];
  module = ./impl.nix;
  ingress = {
    impl = ./non-functional/firewall.nix;
    sslProxyConfig = ./non-functional/ssl.nix;
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
