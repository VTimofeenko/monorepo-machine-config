{ lib, ... }:
let
  rootUUID = "f5206f6a-ef59-4e72-b6d0-041e7567376e";
  swapUUID = "6f03849f-bbc6-4c53-af20-e99fd7143431";
in
{
  # Boot
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "nvme"
        "usb_storage"
        "sd_mod"
        "sdhci_pci"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
  };

  # File systems
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/${rootUUID}";
      fsType = "ext4";
      options = [ "noatime" ];
    };
    "/boot" = {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
    };
  };
  swapDevices = [ { device = "/dev/disk/by-uuid/${swapUUID}"; } ];

  # Misc
  system.stateVersion = "24.05";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkForce true;
  networking.wireless.enable = false;
  hardware.enableRedistributableFirmware = true;
  services.fstrim.enable = true;
  # Imports
  imports = [ ./experimental-networkd.nix ];
}
