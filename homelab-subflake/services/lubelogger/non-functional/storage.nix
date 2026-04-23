/**
  Ensures that a partition is mounted for `srv:lubelogger`
*/
{ config, ... }:
let
  serviceName = "lubelogger";
  stateDir = "/var/lib/${config.services.${serviceName}.dataDir}";
in
{
  systemd = {
    services.${serviceName}.unitConfig.RequiresMountsFor = [ stateDir ];
    mounts = [
      {
        what = "/dev/disk/by-label/${serviceName}";
        where = stateDir;
        options = "noatime";
      }
    ];
  };
}
