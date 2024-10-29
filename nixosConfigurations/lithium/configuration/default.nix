{ pkgs, nixos-hardware, ... }:
{
  # Boot
  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "usbhid"
        "usb_storage"
      ];
      kernelModules = [
        "xhci_pci"
        "usbhid"
        "usb_storage"
      ];
    };
    # Necessary for USB boot(!)
    kernelPackages = pkgs.linuxPackages_rpi4;
    blacklistedKernelModules = [
      "bluetooth"
      "btusb"
    ];
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
    };
  };

  # File systems
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
  };
  swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];

  # Misc
  hardware.enableRedistributableFirmware = true;
  system.stateVersion = "22.05";

  # Imports
  imports = [
    nixos-hardware.nixosModules.raspberry-pi-4
  ];
}
