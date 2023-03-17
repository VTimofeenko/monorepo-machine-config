{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./nvidia2070.nix
    ];
  # Use the systemd-boot EFI boot loader.
  boot =
    {
      loader =
        {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
        };
      initrd =
        {
          availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "sd_mod" ];
          kernelModules = [ ];
          luks.devices."crypt-root".device = "/dev/disk/by-uuid/687e04e3-c128-4736-8199-2a7a563b4a97";
        };
      kernelModules = [ "kvm-amd" ];
      tmpOnTmpfs = true;
      tmpOnTmpfsSize = "8G";
    };

  networking.hostName = "neptunium";
  networking.wireless.enable = lib.mkForce false;
  networking.useDHCP = lib.mkForce true;

  services.openssh =
    {
      enable = true;
      permitRootLogin = "yes";
    };

  networking.firewall.enable = false;
  environment.systemPackages = [ pkgs.git ];

  system.stateVersion = "22.11";
  fileSystems."/" =
    {
      device = "/dev/mapper/crypt-root";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

  swapDevices =
    [
      { device = "/dev/disk/by-label/swap"; }
    ];
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.video.hidpi.enable = lib.mkDefault true;
  time.hardwareClockInLocalTime = true; # otherwise dual-booted Windows has wrong time
}
