# [[file:../../../../new_project.org::*Frame.work specific][Frame.work specific:1]]
{
  pkgs,
  lib,
  nixos-hardware,
  ...
}:
{
  imports = [
    nixos-hardware.nixosModules.framework-13-7040-amd
  ];
  hardware = {
    enableRedistributableFirmware = true; # NOTE: required for wifi to work
    graphics = {
      extraPackages = [ pkgs.rocmPackages.clr.icd ];
      enable32Bit = true;
    };

    # Mis-detected by nixos-generate-config
    # https://github.com/NixOS/nixpkgs/issues/171093
    # https://wiki.archlinux.org/title/Framework_Laptop#Changing_the_brightness_of_the_monitor_does_not_work
    acpilight.enable = lib.mkDefault true;

    # Needed for desktop environments to detect/manage display brightness
    sensor.iio.enable = lib.mkDefault true;

    amdgpu.initrd.enable = true;
  };

  boot = {
    kernelParams = [
      # Fixes white flickering after resume/unlock
      "amdgpu.sg_display=0"
    ];
  };

  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
  };
}
# Frame.work specific:1 ends here
