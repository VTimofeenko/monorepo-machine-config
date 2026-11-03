/**
  NixOS-level smartcard stack: pcscd and udev rules for YubiKey/Nitrokey.
  HM-level GPG/SSH config lives in the private counterpart.
*/
{ pkgs, ... }:
{
  services = {
    pcscd.enable = true;
    udev = {
      packages = [
        pkgs.yubikey-personalization
        pkgs.nitrokey-udev-rules
      ];
      extraRules = ''
        # Nitrokey 3 firmware
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="20a0", ATTRS{idProduct}=="42b2", TAG+="uaccess"
        SUBSYSTEM=="tty", ATTRS{idVendor}=="20a0", ATTRS{idProduct}=="42b2", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="20a0", ATTRS{idProduct}=="42b2", TAG+="uaccess"

        # Nitrokey 3 bootloader
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="20a0", ATTRS{idProduct}=="42dd", TAG+="uaccess"
      '';
    };
  };
}
