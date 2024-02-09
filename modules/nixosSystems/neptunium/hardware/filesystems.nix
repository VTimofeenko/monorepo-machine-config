# [[file:../../../../new_project.org::*Neptunium filesystems][Neptunium filesystems:1]]
_: {
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
# Neptunium filesystems:1 ends here
