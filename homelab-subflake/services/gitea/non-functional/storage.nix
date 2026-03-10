{ config, lib, ... }:
let
  inherit (lib.localLib) mkCryptTab mkLuksMount;
  luks = {
    device_name = "gitea_data";
    UUID = "fdcc8af6-7b4e-443d-b10d-0cd23c412dee";
  };
in
{
  # Order the unit after mount is up
  systemd.services.gitea.unitConfig.RequiresMountsFor = lib.mkOptionDefault [
    config.services.gitea.stateDir
  ];

  # LUKS setup
  environment.etc."crypttab".text = mkCryptTab { inherit (luks) device_name UUID; };
  systemd.mounts = [
    (mkLuksMount {
      inherit (luks) device_name;
      target = config.services.gitea.stateDir;
    })
  ];
}
