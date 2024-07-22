/*
  Backup implementation for gitea.

  For now only rotates on-device dumps.

  # TODO: implement properly
*/
{ config, lib, ... }:
let
  inherit (config.services) gitea;
in
{
  systemd.tmpfiles.rules =
    assert lib.assertMsg gitea.dump.enable "This module needs gitea.dump.enable but it's disabled";
    [ "d ${gitea.dump.backupDir}/ 0750 ${gitea.user} ${gitea.group} 14d" ];
}
