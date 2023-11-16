# [[file:../../new_project.org::*Keyboard][Keyboard:1]]
{ lib, pkgs, ... }: {
  # taken from https://github.com/dygmalab/bazecor/blob/159eed1d37f3fd1fbf5c17023c12bb683b778281/src/main/index.js#l223
  services.udev.extraRules = ''
    subsystem=="usb", attrs{idvendor}=="1209", attrs{idproduct}=="2201", group="users", mode="0666"
    subsystem=="usb", attrs{idvendor}=="1209", attrs{idproduct}=="2200", group="users", mode="0666"
  '';
}
# Keyboard:1 ends here
