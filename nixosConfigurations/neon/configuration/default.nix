{ lib, ... }:
let
  settings.bootDevice = "/dev/nvme0n1p1";
  settings.rootDevice = "/dev/disk/by-label/nixos";
  settings.swapDevice = "/dev/disk/by-uuid/84cc88b6-3ea2-42fa-a606-c83346e08e56";
in
{
  # Boot
  boot = {
    initrd.availableKernelModules = [
      "vmd"
      "xhci_pci"
      "ahci"
      "nvme"
      "usb_storage"
      "usbhid"
      "sd_mod"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  fileSystems."/boot" = {
    device = settings.bootDevice;
    fsType = "vfat";
  };

  # File systems
  fileSystems."/" = {
    device = settings.rootDevice;
    fsType = "ext4";
    options = [
      "defaults"
      "noatime"
    ];
  };
  swapDevices = [ { device = settings.swapDevice; } ];

  # Misc
  system.stateVersion = "24.11";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkForce true;
  systemd.network.links."10-phy-lan".linkConfig.WakeOnLan = "magic";

  # Imports
  imports = [
    ./hw-acceleration.nix
    ./storage.nix
    (lib.localLib.mkMicroVMModules "neodymium")
    (lib.localLib.mkMicroVMModules "promethium")
  ];

  microvm.vms.promethium.config.microvm.mem = 2049;
}
