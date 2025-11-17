{ lib, config, ... }:
let
  srvName = "prometheus";
  inherit (lib.homelab) getServiceIP;
in
{
  services.prometheus = {
    enable = true;
    retentionTime = "120d";
    listenAddress = getServiceIP srvName;
  };

  # Mounts
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
