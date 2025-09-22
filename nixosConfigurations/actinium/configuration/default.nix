{ lib, modulesPath, ... }:
{
  # Boot
  boot = {
    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
      device = "nodev";
    };
    initrd = {
      availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "xen_blkfront"
        "vmw_pvscsi"
      ];
      kernelModules = [ "nvme" ];
    };
  };

  # File systems
  fileSystems = {
    "/" = {
      device = "/dev/sda1";
      fsType = "ext4";
      options = [ "noatime" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/D5BC-D210";
      fsType = "vfat";
    };
  };

  # Misc
  system.stateVersion = "24.05";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  # Imports
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./tailscale.nix
  ];
}
