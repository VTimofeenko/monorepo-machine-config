{ lib, ... }:
{
  # Boot
  boot = {
    initrd = {
      availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "virtio_pci"
        "virtio_scsi"
        "sd_mod"
        "sr_mod"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ ];
    extraModulePackages = [ ];
    loader.grub = {
      enable = true;
      device = "/dev/sda";
    };
  };

  # File systems
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS";
    fsType = "ext4";
    options = [
      "defaults"
      "noatime"
    ];
  };

  # Misc
  system.stateVersion = "24.05";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkForce true;

  # Imports
  imports = [
    ./experimental-wg-srvnet.nix
  ];
}
