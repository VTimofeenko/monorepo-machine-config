/** Configures support for USB-based RTL SDR */
{ pkgs, ... }:
{
  hardware.rtl-sdr.enable = true;
  users.users.spacecadet.extraGroups = [ "plugdev" ];
  environment.systemPackages = [
    pkgs.sdrpp
    pkgs.rtl-sdr
  ];
}
