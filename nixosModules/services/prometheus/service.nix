{ config, ... }:
let
  srvName = "prometheus";
in
{
  services.prometheus = {
    enable = true;
    retentionTime = "30d";
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

}
