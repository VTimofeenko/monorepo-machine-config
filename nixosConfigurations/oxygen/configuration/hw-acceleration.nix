/**
  Enables hardware acceleration for ffmpeg transcoding.

  Source: https://wiki.nixos.org/wiki/Nvidia
*/
{ config, ... }:
{

  hardware.graphics.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Newest drivers will complain:
    # NVRM: The NVIDIA GeForce GTX 870M GPU installed in this system is
    # NVRM:  supported through the NVIDIA 470.xx Legacy drivers. Please
    # NVRM:  visit http://www.nvidia.com/object/unix.html for more
    # NVRM:  information.  The 565.77 NVIDIA driver will ignore
    # NVRM:  this GPU.  Continuing probe...
    package = config.boot.kernelPackages.nvidiaPackages.legacy_470;

    modesetting.enable = true;

    powerManagement.enable = false;

    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    # nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
  };
}
