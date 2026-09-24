# Nvidia 2070, wlroots-based compositor (niri)
{ pkgs, ... }:
{
  # The settings are applied for both x11 and wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # nvidia-drm.modeset=1 is required for some wayland compositors, e.g. niri
    modesetting.enable = true;
    package = pkgs.linuxKernel.packages.linux_6_1.nvidia_x11_beta;
    # Suspend does not work with open
    open = false;
    # Needed for suspend
    powerManagement.enable = true;
    forceFullCompositionPipeline = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_6_1;

  environment.variables = {
    # NOTE: needed for mouse cursor to be visible
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER = "vulkan";
  };
}
