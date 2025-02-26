let
  serviceName = "gitea";
in
rec {
  default = [
    module
    ingress.impl
    storage.impl
    ./non-functional/bkp.nix
    backups.impl
  ];
  module = ./gitea.nix;

  ingress = {
    impl = ./non-functional/firewall.nix;
    sslProxyConfig = ./non-functional/ssl.nix;
  };

  monitoring = {
    # TODO: implement here
    impl = ./non-functional/monitoring.nix;
  };
  logging = false; # TODO: implement
  storage = {
    impl = ./non-functional/storage.nix;
  };
  backups = rec {
    enable = true;
    schedule = "daily";
    paths = [ "/var/lib/gitea" ];
    impl =
      if enable then import ./non-functional/backups.nix { inherit paths schedule serviceName; } else { };
    # TODO: remote!
  };
  dashboard = {
    category = "Dev";
    links = [
      {
        description = "Local GitHub alternative";
        icon = "gitea";
        name = "Gitea";
      }
    ];
  };
}
