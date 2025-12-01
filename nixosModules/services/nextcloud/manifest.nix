let
  serviceName = "nextcloud";
in
rec {
  default = [
    module
    # storage.impl
    ingress.impl
    backups.impl
    observability.metrics.impl
  ];
  module = ./. + "/${serviceName}.nix";

  ingress =
    let
      port = 80;
    in
    {
      impl = import ./non-functional/firewall.nix { inherit port serviceName; };
      sslProxyConfig = import ./non-functional/ssl.nix { inherit port serviceName; };
    };

  observability = {
    enable = true;
    metrics = rec {
      enable = true;
      impl = if enable then import ./non-functional/metrics.nix { inherit port; } else { };
      port = 9205;
    };
    alerts = rec {
      enable = true;
      grafanaImpl = if enable then import ./non-functional/alerts.nix { inherit serviceName; } else { };
    };
  };

  backups = rec {
    enable = true;
    paths = [ "/var/lib/nextcloud" ];
    exclude = [ "appdata_ochcggcdayyl/preview" ];
    impl =
      if enable then { lib, ... }: lib.localLib.mkBkp { inherit paths exclude serviceName; } else { };
  };

  dashboard = {
    category = "Home";
    links = [
      {
        icon = "nextcloud";
        name = "Nextcloud";
      }
    ];
  };
}
