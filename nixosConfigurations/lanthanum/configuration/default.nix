{ lib, config, ... }:
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
      version = 2;
      device = "/dev/sda";
    };
  };

  # File systems
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Network
  networking = {
    useDHCP = false;
    interfaces.ens3.useDHCP = true;
  };

  # Misc
  system.stateVersion = "21.11";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Imports
}
