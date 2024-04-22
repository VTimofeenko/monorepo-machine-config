/**
  NixOS configuration for oxygen.
*/
{
  pkgs,
  config,
  lib,
  ...
}:
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
        "ehci_pci"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ ];
    };
    kernelModules = [
      "kvm-intel"
      "wl"
      "b43" # Needed for broadcom
    ];
    extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
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
    # TODO: nvr?
  };
  swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];

  # Misc
  system.stateVersion = "23.11";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkForce true;
  systemd.services.console-blank = {
    enable = true;
    description = "Blank and powerdown the monitor";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/setterm --blank 1 --powerdown 1";
      TTYPath = "/dev/console";
      StandardOutput = "tty";
    };
    wantedBy = [ "multi-user.target" ];
    environment = {
      TERM = "linux";
    };
  };

  services.logind.lidSwitch = "ignore";

  # Networking, specific to this host
  networking = {
    wireless.enable = false;
    networkmanager.enable = true; # For whatever reason this host needed networkmanager to get to wifi. TODO: change this to declarative management and add wireless module
  };

  # Imports
  imports = [ ];
}
