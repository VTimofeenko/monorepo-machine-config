{ lib, config, ... }:
let
  srvName = "prometheus";
in
{
  services.prometheus = {
    enable = true;
    retentionTime = "120d";
  };

  # Mounts
  # TODO: move to storage.impl
  systemd = {
    # Reconstruct the workdir
    services.prometheus.unitConfig.RequiresMountsFor = [
      "/var/lib/${config.services.prometheus.stateDir}"
    ];
    mounts = [
      {
        what = "/dev/disk/by-label/${srvName}";
        where = "/var/lib/${config.services.prometheus.stateDir}";
        options = "noatime";
      }
    ];
  };

  imports = [
    ./synology
    ./service-scraping
    ./healthchecks-scraping.nix
  ]
  ++ lib.localLib.mkImportsFromDir ./functional;
}
