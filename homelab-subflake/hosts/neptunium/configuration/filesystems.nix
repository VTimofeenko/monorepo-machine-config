{
  fileSystems = {
    "/" = {
      device = "/dev/mapper/crypt-root";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/3FFD-D8B4";
      fsType = "vfat";
    };
  };
  swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];
}
