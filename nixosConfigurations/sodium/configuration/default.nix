{
  nixos-hardware,
  pkgs,
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
      ];
      kernelModules = [
        "xhci_pci"
        "usbhid"
        "usb_storage"
      ];
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
    };
  };

  # File systems
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  # Misc
  system.stateVersion = "25.05";

  hardware.enableRedistributableFirmware = false;
  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];
  # Imports
  imports = [
    nixos-hardware.nixosModules.raspberry-pi-3
  ];

  networking.wireless.extraConfig = ''
    country=US
    p2p_disabled=1
  '';
}
