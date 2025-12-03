let
  serviceName = "restic-server";
in
rec {
  default = [
    module
    ingress.impl
    storage.impl
    observability.metrics.impl
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

  observability = {
    enable = true;
    metrics = rec {
      enable = true;
      impl = if enable then import ./non-functional/metrics.nix else { };
    };
    alerts = rec {
      enable = true;
      grafanaImpl = if enable then import ./non-functional/alerts.nix { inherit serviceName; } else { };
    };
  };

  storage = {
    impl = ./non-functional/storage.nix;
  };
  backups = false;
}
