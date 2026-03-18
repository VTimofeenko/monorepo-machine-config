/**
  Node has:
  - UHD Graphics 730
  - ARC 310 GPU

  The point is to use this machine for transcoding.

  References:

  - https://jellyfin.org/docs/general/administration/hardware-acceleration/intel
  - https://github.com/intel/media-delivery/blob/master/doc/benchmarks/intel-data-center-gpu-flex-series/intel-data-center-gpu-flex-series.rst
*/
{
  pkgs,
  nixos-hardware,
  ...
}:
{
  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-ocl
    vpl-gpu-rt
    intel-compute-runtime
    intel-vaapi-driver
  ];

  imports = [
    nixos-hardware.nixosModules.common-gpu-intel
  ];
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
  hardware.intelgpu.driver = "xe";

  # Arc GPU support needs fresh kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  environment.systemPackages = [
    # `lspci`
    pkgs.pciutils
    # `vainfo` lives here
    pkgs.libva-utils
    # for `intel_gpu_top`
    pkgs.intel-gpu-tools
  ];

  # Needed for correct Arc driver?
  hardware.enableRedistributableFirmware = true;
}
