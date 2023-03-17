{ config, pkgs, lib, ... }:
{
  # The settings are applied for both x11 and wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  # nvidia-drm.modeset=1 is required for some wayland compositors, e.g. sway
  hardware.nvidia.modesetting.enable = true;
}
