let
  serviceName = "gitea";
in
rec {
  default = [
    module
    ingress.impl
    storage.impl
    backups.impl
  ]
  ++ observability.impl;
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

  observability = rec {
    enable = true;
    impl = if enable then [ metrics.impl ] else [ ];
    metrics = rec {
      enable = true;
      path = "/metrics";
      impl = if enable then import ./non-functional/observability/metrics/impl.nix else { };
    };
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
    exclude = [
      "/var/lib/gitea/dump"
      "/var/lib/gitea/tmp"
    ];
    impl =
      if enable then
        { lib, ... }:
        lib.localLib.mkBkp {
          inherit
            paths
            serviceName
            schedule
            exclude
            ;
        }
      else
        { };
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
