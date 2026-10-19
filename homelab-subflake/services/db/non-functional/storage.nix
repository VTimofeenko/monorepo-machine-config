{ config, lib, ... }:
{
  systemd.services.postgresql.unitConfig.RequiresMountsFor = lib.mkOptionDefault [
    config.services.postgresql.dataDir
  ];
  # Temporary home on lithium's spare partition while boron is dead
  # - Previously LUKS volume UUID 1e4cc767-a3f7-4990-9398-27670aed1a29 (`luks_db`)
  fileSystems.${config.services.postgresql.dataDir} = {
    device = "/dev/disk/by-label/maindb";
    fsType = "ext4";
    options = [ "nofail" ];
  };
}
