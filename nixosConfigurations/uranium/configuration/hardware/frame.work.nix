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
    # nixos-hardware.nixosModules.common-cpu-amd-pstate
    # nixos-hardware.nixosModules.common-gpu-amd
    # nixos-hardware.nixosModules.common-pc-laptop
    # nixos-hardware.nixosModules.common-pc-laptop-ssd
  ];
  hardware = {
    enableRedistributableFirmware = true; # NOTE: required for wifi to work
    graphics = {
      extraPackages = [ pkgs.rocmPackages.clr.icd ];
      enable32Bit = true;
    };

    # Custom udev rules
    # services.udev.extraRules = ''
    #   # Fix headphone noise when on powersave
    #   # https://community.frame.work/t/headphone-jack-intermittent-noise/5246/55
    #   SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0xa0e0", ATTR{power/control}="on"
    #   # Ethernet expansion card support
    #   ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8156", ATTR{power/autosuspend}="20"
    # '';

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
      # For Power consumption
      # https://kvark.github.io/linux/framework/2021/10/17/framework-nixos.html

      # "mem_sleep_default=deep"
      # For Power consumption
      # https://community.frame.work/t/linux-battery-life-tuning/6665/156
      # Breaks AMD?
      # "nvme.noacpi=1"
    ];

    # Fix TRRS headphones missing a mic
    # https://community.frame.work/t/headset-microphone-on-linux/12387/3
    # extraModprobeConfig = ''
    #   options snd-hda-intel model=dell-headset-multi
    # '';

    # For GPU support
    # initrd.kernelModules = [ "amdgpu" ];
  };

  # For fingerprint support
  # services.fprintd.enable = lib.mkDefault true;

  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
  };
}
# Frame.work specific:1 ends here
