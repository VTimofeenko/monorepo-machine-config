{ pkgs, ... }:
{
  boot.kernelParams = [ "libata.force=noncq" ];

  fileSystems."/data" = {
    fsType = "btrfs";
    device = "/dev/disk/by-uuid/8cc1e2d2-1ff9-4145-bbac-74a3056a242f";
    options = [
      "defaults"
      "noatime"
    ];
  };

  fileSystems."/vms" = {
    fsType = "btrfs";
    device = "/dev/disk/by-label/VMs";
    options = [
      "defaults"
      "noatime"
    ];
  };

  environment.systemPackages = [
    pkgs.btrfs-progs
    pkgs.smartmontools
    pkgs.iotop
  ];
}
