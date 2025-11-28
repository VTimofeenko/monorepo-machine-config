rec {
  default = [
    module
    ingress.firewall
  ]
  ++ observability.metrics.impl;
  module = ./service.nix;

  ingress.firewall = import ./non-functional/firewall.nix;

  observability = {
    enable = true;
    metrics = rec {
      enable = true;
      impl = if enable then ./non-functional/metrics.nix else { };
      port = 9975;
      path = "/";
    };
    alerts = {
      enable = true;
      grafanaImpl = import ./non-functional/alerts.nix;
    };
  };

  backups.enable = false;
  storage.enable = false;
}
