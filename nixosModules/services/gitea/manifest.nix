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
    logging = {
      enable = true;
      systemdUnit = "gitea.service";
    };
    alerts = {
      enable = true;
      Emergency = [ ];
      Alert = [
        # service availability
        {
          title = "service down";
          query = "up{job=\"gitea-srv-scrape\"}";
        }
        # disk almost full
        {
          title = "disk almost full";
          query = "(vector(0) and on() (((node_filesystem_avail_bytes{mountpoint=\"/var/lib/gitea\"} * 100) / node_filesystem_size_bytes{mountpoint=\"/var/lib/gitea\"}) < 10)) or on() vector(1)";
        }
        # TODO: (needs nginx metrics) error rate over X for a period
        # TODO: (needs new DB) query duration
      ];
    };
  };

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
