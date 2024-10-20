{ lib, ... }:
# let
#   inherit (config) my-data;
#   lan = my-data.lib.getNetwork "lan";
#   thisHostInNetwork = lan.hostsInNetwork.${config.networking.hostName};
# in
{
  # Boot
  boot = {
    # Sets screen timeout to 1 minute
    kernelParams = [ "consoleblank=60" ];
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ehci_pci"
        "ahci"
        "usb_storage"
        "sd_mod"
        "rtsx_pci_sdmmc"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # File systems
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      options = [ "noatime" ];
    };
    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };
  };
  swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];

  # Network
  networking.interfaces.wlan0.useDHCP = lib.mkForce true;
  networking = {
    wireless.enable = lib.mkForce true;
    wireless.interfaces = [ "wlan0" ];
  };

  # Misc
  system.stateVersion = "22.11";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware = {
    cpu.intel.updateMicrocode = lib.mkForce true;
    enableRedistributableFirmware = true;
  };
  services.logind.lidSwitch = "ignore";
  # Imports
  imports = [ ];
}
