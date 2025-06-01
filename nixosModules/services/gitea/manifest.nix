let
  serviceName = "gitea";
in
rec {
  default = [
    module
    ingress.impl
    storage.impl
    backups.impl
  ];
  module = ./gitea.nix;

  ingress =
    let
      sshPort = 22;
      webPort = 3000;
    in
    {
      impl = ./non-functional/firewall.nix;
      sslProxyConfig = ./non-functional/ssl.nix;
    }
    |> builtins.mapAttrs (_: v: import v { inherit sshPort webPort serviceName; });

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
