/**
  Mounts iSCSI LUN to store the restic repos.

  Using this needs impure configuration on NAS side.

  Source: https://discourse.nixos.org/t/configure-iscsi/50773/5
*/
{
  lib,
  config,
  ...
}:

let
  IQN = "iqn.2000-01.com.synology:nas.default-target.c332d8ce746";
in
{
  imports = [
    (lib.localLib.mkIscsi {
      targetIqn = IQN;
      mountPoint = config.services.restic.server.dataDir;
      part = 1;
      initiatorName = "iqn.2024-09.com.nixos:my-nixos-initiator";
    })
  ];

  systemd.services.restic-rest-server.unitConfig.RequiresMountsFor = [
    config.services.restic.server.dataDir
  ];
}
