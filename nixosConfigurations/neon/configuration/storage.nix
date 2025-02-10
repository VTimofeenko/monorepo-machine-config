{ pkgs, ... }:
{
  boot.kernelParams = [ "libata.force=noncq" ];

  fileSystems."/data" = {
    fsType = "btrfs";
    device = "/dev/sda";
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
