{
  pkgs,
  lib,
  nixos-hardware,
  ...
}:
{
  # Boot
  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "hid_logitech_hidpp"
        "xhci_pci_renesas"
      ];
      kernelModules = [
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "hid_logitech_hidpp"
        "xhci_pci_renesas"
      ];
    };
    supportedFilesystems = lib.mkForce [
      "btrfs"
      "reiserfs"
      "vfat"
      "f2fs"
      "xfs"
      "ntfs"
      "cifs"
      "ext4"
    ];
    kernelPackages = pkgs.linuxPackages_latest;
    tmp = {
      useTmpfs = true;
      tmpfsSize = "1G";
    };
    kernelParams = [
      "8250.nr_uarts=1"
      "console=ttyAMA0,115200"
      "console=tty1"
      "boot.shell_on_fail"
    ];
    consoleLogLevel = 7;
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
      raspberryPi = {
        firmwareConfig = ''
          dtparam=sd_poll_once=on
          dtoverlay=dwc2,dr_mode=host
        '';
      };
    };
  };

  # File systems
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  # Network
  networking.interfaces.wlan0.useDHCP = lib.mkForce true;
  networking = {
    wireless = {
      enable = lib.mkForce true;
      interfaces = [ "wlan0" ];
    };
  };

  # Misc
  hardware.enableRedistributableFirmware = true;
  system.stateVersion = "22.05";

  # Imports
  imports = [ nixos-hardware.nixosModules.raspberry-pi-4 ];
}
