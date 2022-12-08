{ lib, pkgs, ... }:

{
  # Taken from https://github.com/Dygmalab/Bazecor/blob/159eed1d37f3fd1fbf5c17023c12bb683b778281/src/main/index.js#L223
  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="2201", GROUP="users", MODE="0666"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="2200", GROUP="users", MODE="0666"
  '';
}
