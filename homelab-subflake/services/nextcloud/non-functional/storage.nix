{ lib, config, ... }:
let
  inherit (config.services.nextcloud) home;
in
{
  # Keep services off the root disk if the drive is missing (`nofail`)
  systemd.services = lib.genAttrs [ "nextcloud-setup" "phpfpm-nextcloud" "nextcloud-cron" ] (_: {
    unitConfig.RequiresMountsFor = [ home ];
  });

  # Temporary home on the former docspell partition while boron is dead
  # - Previously LUKS volume UUID `0523d6c9-9ea5-4296-85a2-5655189fd0b5` (`luks_nextcloud`)
  fileSystems.${home} = {
    device = "/dev/disk/by-label/nextcloud-tmp";
    fsType = "ext4";
    options = [ "nofail" ];
  };
}
