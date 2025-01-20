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
  lib,
  nixos-hardware,
  ...
}:
{
  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-ocl
    vpl-gpu-rt
    intel-media-sdk
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
    # This ffmpeg build has `av1_qsv` which allows for fast transcoding on ARC
    (pkgs.ffmpeg.override (
      # Override is constructed by turning a list of flags into an attrset (`["foo"] => { withFoo = true; }`)
      [
        # https://www.reddit.com/r/IntelArc/comments/1at6gk0/comment/kv8zaus/
        "Drm"
        "GPL"
        "Aom"
        "Dav1d"
        "FdkAac"
        "Freetype"
        "Opus"
        "Mp3lame"
        "Vorbis"
        "Vpl"
        "X264"
        "X265"
        "Pic"
        "Unfree" # This part is disabled
        "RuntimeCPUDetection"
        "Vaapi"
        # https://trac.ffmpeg.org/wiki/Hardware/QuickSync
        "Vpl"
      ]
      |> map (it: {
        "with${it}" = true;
      })
      |> lib.mergeAttrsList
    ))
    # for `intel_gpu_top`
    pkgs.intel-gpu-tools
  ];

  # Needed for correct Arc driver?
  hardware.enableRedistributableFirmware = true;
}
