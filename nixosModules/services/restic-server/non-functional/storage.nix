/**
  Mounts iSCSI LUN to store the restic repos.

  Using this needs impure configuration on NAS side.

  Source: https://discourse.nixos.org/t/configure-iscsi/50773/5
*/
{ lib, pkgs, config, ... }:

let
  IP = "nas" |> lib.flip lib.homelab.getHostIpInNetwork "lan";
  IQN = "iqn.2000-01.com.synology:nas.default-target.c332d8ce746";
in
{
  services.openiscsi = {
    enable = true;
    name = "iqn.2024-09.com.nixos:my-nixos-initiator";
    discoverPortal = IP;
  };
  environment.systemPackages = [
    pkgs.openiscsi
  ];

  boot.kernelModules = [ "iscsi_tcp" ];

  systemd.services.iscsi-login-lingames = {
    description = "Login to iSCSI target ${IQN}";
    after = [
      "network.target"
      "iscsid.service"
    ];
    wants = [ "iscsid.service" ];
    serviceConfig = {
      ExecStartPre = "${pkgs.openiscsi}/bin/iscsiadm -m discovery -t sendtargets -p ${IP}";
      ExecStart = "${pkgs.openiscsi}/bin/iscsiadm -m node -T ${IQN} -p ${IP} --login";
      ExecStop = "${pkgs.openiscsi}/bin/iscsiadm -m node -T ${IQN} -p ${IP} --logout";
      Restart = "on-failure";
      RemainAfterExit = true;
    };
    wantedBy = [ "multi-user.target" ];
  };

  fileSystems."${config.services.restic.server.dataDir}" = {
    device = "/dev/disk/by-path/ip-${IP}:3260-iscsi-iqn.2000-01.com.synology:nas.default-target.c332d8ce746-lun-1-part1";
    fsType = "ext4";
    options = [
      "_netdev"
      "nofail"
      "noatime"
    ];
  };

  systemd.services.restic-rest-server.unitConfig.RequiresMountsFor = [ config.services.restic.server.dataDir ];
}
