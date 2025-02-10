rec {
  default = [
    module
    ingress.internal
  ];
  module = ./impl.nix;
  ingress = {
    internal = ./firewall.nix;
    sslProxyConfig = ./ssl.nix;
  };

  monitoring = false; # TODO: implement
  logging = false; # TODO: implement
  # Stateless service
  backups = false;
  storage = false;
}
