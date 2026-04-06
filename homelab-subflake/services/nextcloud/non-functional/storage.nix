{ lib, config, ... }:
let
  inherit (lib.localLib) mkCryptTab mkLuksMount;
  luks = {
    device_name = "luks_nextcloud";
    UUID = "0523d6c9-9ea5-4296-85a2-5655189fd0b5";
  };
in
{
  systemd.services.nextcloud-setup.unitConfig.RequiresMountsFor = [ config.services.nextcloud.home ];

  environment.etc."crypttab".text = mkCryptTab { inherit (luks) device_name UUID; };
  systemd.mounts = [
    (mkLuksMount {
      inherit (luks) device_name;
      target = config.services.nextcloud.home;
    })
  ];
}
