# [[file:../../new_project.org::*Keyboard][Keyboard:1]]
_: {
  # taken from https://github.com/dygmalab/bazecor/blob/159eed1d37f3fd1fbf5c17023c12bb683b778281/src/main/index.js#l223
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idvendor}=="1209", ATTR{idproduct}=="2201", GROUP="users", MODE="0666"
    SUBSYSTEM=="usb", ATTR{idvendor}=="1209", ATTR{idproduct}=="2200", GROUP="users", MODE="0666"
  '';
}
# Keyboard:1 ends here
