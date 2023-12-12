{ pkgs, lib, nixos-hardware, ... }:

{
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };
  # NOTE: USB device used to be here. Not anymore since it is borked
  # fileSystems."/nix" = {
  #   device = "/dev/disk/by-label/nix-store";
  #   fsType = "ext4";
  #   neededForBoot = true;
  #   options = [ "noatime" ];
  # };
  # NOTE: swap seems slow lately
  # swapDevices = [{ label = "swap"; }];
  imports = [ nixos-hardware.nixosModules.raspberry-pi-4 ];
  boot = {
    initrd = {
      availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" "hid_logitech_hidpp" "xhci_pci_renesas" ];
      kernelModules = [ "xhci_pci" "usbhid" "usb_storage" "hid_logitech_hidpp" "xhci_pci_renesas" ];
    };
    supportedFilesystems = lib.mkForce [ "btrfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" "ext4" ];
    kernelPackages = pkgs.linuxPackages_latest;
    tmp = {
      useTmpfs = true;
      tmpfsSize = "256M";
    };
    kernelParams = [
      "8250.nr_uarts=1"
      "console=ttyAMA0,115200"
      "console=tty1"
      "boot.shell_on_fail"
    ];
    consoleLogLevel = 7;
    loader = {
      raspberryPi = {
        firmwareConfig = ''
          dtparam=sd_poll_once=on
          dtoverlay=dwc2,dr_mode=host
        '';
        # enable = true;
        # version = 4;
      };
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };
  hardware.enableRedistributableFirmware = true;

  networking = {
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
    enableIPv6 = false;
  };

  system.stateVersion = "22.11";
}
