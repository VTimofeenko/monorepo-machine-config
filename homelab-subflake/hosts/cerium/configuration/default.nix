{ lib, ... }:
{
  # Boot
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/sda";
      };
    };
    initrd = {
      availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "virtio_pci"
        "virtio_scsi"
        "sd_mod"
        "sr_mod"
      ];
    };
    kernelModules = [ "kvm-intel" ];
  };

  # File systems
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];

  # Misc
  system.stateVersion = "24.05";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkForce true;
  networking.interfaces.ens3.useDHCP = true;
  services.qemuGuest.enable = true;

  # Imports
  imports = [ ];
}
