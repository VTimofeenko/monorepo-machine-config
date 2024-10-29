{ lib, nixos-hardware, ... }:
{
  # Boot
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd = {
      availableKernelModules = [
        "ahci"
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
  };

  # File systems
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/8b8ed380-e3b4-4c64-95fa-d3c14acd0f1e";
      fsType = "ext4";
      options = [ "noatime" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/4ECC-8FD1";
      fsType = "vfat";
    };
  };
  swapDevices = [ { device = "/dev/disk/by-uuid/51449286-d2ba-4f22-b951-0697af940370"; } ];

  # Misc
  system.stateVersion = "23.11";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkForce true;
  networking.wireless.enable = false;
  # Imports
  imports = [
    nixos-hardware.nixosModules.framework-11th-gen-intel
  ];
}
