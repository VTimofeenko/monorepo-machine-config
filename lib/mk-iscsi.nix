{
  targetIqn,
  mountPoint,
  lun ? 1,
  part ? null,
  fsType ? "ext4",
  mountOptions ? [
    "_netdev"
    "nofail"
    "noatime"
  ],
  initiatorName,
}:
{
  pkgs,
  lib,
  ...
}:
let
  devicePath =
    [
      "/dev/disk/by-path/ip-"
      ip
      ":3260-iscsi-"
      targetIqn
      "-lun-"
      (toString lun)
      (lib.optionalString (!builtins.isNull part) "-part${toString part}")
    ]
    |> lib.concatStrings;
  serviceName = "iscsi-login-${builtins.replaceStrings [ "/" ] [ "-" ] mountPoint}";
  ip = "nas" |> lib.flip lib.homelab.getHostIpInNetwork "lan";
in
{
  services.openiscsi = {
    enable = true;
    name = initiatorName;
    discoverPortal = ip;
  };
  environment.systemPackages = [ pkgs.openiscsi ];
  boot.kernelModules = [ "iscsi_tcp" ];

  systemd.services."${serviceName}" = {
    description = "Login to iSCSI target ${targetIqn}";
    after = [
      "network.target"
      "iscsid.service"
    ];
    wants = [ "iscsid.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStartPre = "${pkgs.openiscsi}/bin/iscsiadm -m discovery -t sendtargets -p ${ip}";
      ExecStart = "${pkgs.openiscsi}/bin/iscsiadm -m node -T ${targetIqn} -p ${ip} --login";
      ExecStop = "${pkgs.openiscsi}/bin/iscsiadm -m node -T ${targetIqn} -p ${ip} --logout";
      Restart = "on-failure";
      RemainAfterExit = true;
      SuccessExitStatus = 15; # `ISCSI_ERR_SESS_EXISTS`, so that restarts are considered OK.
    };
    wantedBy = [ "multi-user.target" ];
  };

  fileSystems."${mountPoint}" = {
    device = devicePath;
    fsType = fsType;
    options = mountOptions;
  };
}
