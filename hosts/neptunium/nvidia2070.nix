{ config, pkgs, lib, ... }:
{
  # The settings are applied for both x11 and wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  # nvidia-drm.modeset=1 is required for some wayland compositors, e.g. sway
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
  };

  environment.variables = {
    # NOTE: needed for mouse cursor to be visible
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER = "vulkan";
  };
  # Apps on sway seem to be unusable without this:
  hardware.nvidia.forceFullCompositionPipeline = true;
}
