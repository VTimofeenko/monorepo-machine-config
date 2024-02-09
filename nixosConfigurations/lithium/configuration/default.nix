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
  # TODO: Move this to label
  swapDevices = [ { device = "/dev/disk/by-uuid/318726e3-add5-4460-89c2-f141e47da4a9"; } ];

  # Misc
  hardware.enableRedistributableFirmware = true;
  system.stateVersion = "22.05";

  # Imports
  imports = [ nixos-hardware.nixosModules.raspberry-pi-4 ];
}
