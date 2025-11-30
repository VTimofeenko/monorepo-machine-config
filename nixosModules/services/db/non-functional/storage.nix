{ config, lib, ... }:
let
  luks = {
    device_name = "luks_db";
    UUID = "1e4cc767-a3f7-4990-9398-27670aed1a29";
  };
in
{
  systemd.services.postgresql.unitConfig.RequiresMountsFor = lib.mkOptionDefault [
    config.services.postgresql.dataDir
  ];
  environment.etc."crypttab".text = lib.localLib.mkCryptTab { inherit (luks) device_name UUID; };
  systemd.mounts = [
    (lib.localLib.mkLuksMount {
      inherit (luks) device_name;
      target = config.services.postgresql.dataDir;
    })
  ];
}
