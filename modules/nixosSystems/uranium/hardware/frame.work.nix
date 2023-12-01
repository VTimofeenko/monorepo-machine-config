# [[file:../../../../new_project.org::*Frame.work specific][Frame.work specific:1]]
{ pkgs
, lib
, config
, nixos-hardware
, ...
}:
{
  imports = [
    # nixos-hardware.nixosModules.common-cpu-intel
    nixos-hardware.nixosModules.common-cpu-amd
    nixos-hardware.nixosModules.common-pc-laptop
    nixos-hardware.nixosModules.common-pc-laptop-ssd
    # TODO:use proper amd module from nixos hardware
  ];
  # high-resolution display
  # NOTE: no longer works for 23.05
  # hardware.video.hidpi.enable = lib.mkDefault true;
  # NOTE: required for wifi to work
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  boot = {
    kernelParams = [
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
    extraModprobeConfig = ''
      options snd-hda-intel model=dell-headset-multi
    '';

    # For GPU support
    initrd.kernelModules = [ "amdgpu" ];
  };

  # For fingerprint support
  /* services.fprintd.enable = lib.mkDefault true; */

  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
  };

  hardware.opengl.extraPackages = builtins.attrValues { inherit (pkgs) rocm-opencl-icd rocm-opencl-runtime; };
  hardware.opengl = {
    driSupport = true;
    driSupport32Bit = true;
  };

  # Custom udev rules
  services.udev.extraRules = ''
    # Fix headphone noise when on powersave
    # https://community.frame.work/t/headphone-jack-intermittent-noise/5246/55
    SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0xa0e0", ATTR{power/control}="on"
    # Ethernet expansion card support
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8156", ATTR{power/autosuspend}="20"
  '';

  # Mis-detected by nixos-generate-config
  # https://github.com/NixOS/nixpkgs/issues/171093
  # https://wiki.archlinux.org/title/Framework_Laptop#Changing_the_brightness_of_the_monitor_does_not_work
  hardware.acpilight.enable = lib.mkDefault true;

  # Needed for desktop environments to detect/manage display brightness
  hardware.sensor.iio.enable = lib.mkDefault true;

  # HiDPI
  # Leaving here for documentation
  # hardware.video.hidpi.enable = lib.mkDefault true;

  # Fix font sizes in X
  # services.xserver.dpi = 200;

}
# Frame.work specific:1 ends here
