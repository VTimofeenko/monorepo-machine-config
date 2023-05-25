# [[file:../../../../new_project.org::*Nvidia 2070 with wayland][Nvidia 2070 with wayland:1]]
{ config, pkgs, lib, ... }:
{
  # The settings are applied for both x11 and wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # nvidia-drm.modeset=1 is required for some wayland compositors, e.g. sway
    modesetting.enable = true;
    package = pkgs.linuxKernel.packages.linux_6_1.nvidia_x11_beta;
    # Suspend does not work with open
    # open = true;
    # Needed for suspend
    powerManagement.enable = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_6_1;

  environment.variables = {
    # NOTE: needed for mouse cursor to be visible
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER = "vulkan";
  };
  # Apps on wayland seem to be unusable without this:
  hardware.nvidia.forceFullCompositionPipeline = true;
  hardware.video.hidpi.enable = lib.mkDefault true;
}
# Nvidia 2070 with wayland:1 ends here
