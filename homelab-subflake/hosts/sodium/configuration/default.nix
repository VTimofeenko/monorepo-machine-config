{
  inputs,
  pkgs,
  lib,
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
  boot.kernel.sysctl."vm.mmap_rnd_bits" = lib.mkForce 18;

  # Misc
  system.stateVersion = "25.05";

  hardware.enableRedistributableFirmware = false;
  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];
  # Imports
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-3
    ./impermanence.nix
  ];

  networking.wireless.extraConfig = ''
    country=US
    p2p_disabled=1
  '';
}
