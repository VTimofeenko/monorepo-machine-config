# [[file:../../../../new_project.org::*Neptunium specific hardware][Neptunium specific hardware:1]]
{ pkgs, config, lib, ... }:
{
  imports = [
    ./nvidia-wayland.nix # (ref:nvidia-wayland-import)
    ./bootloader.nix # (ref:neptunium-bootloader-import)
    ./filesystems.nix # (ref:neptunium-filesystems-import)
    ./network.nix # (ref:neptunium-network-import)
  ];
  system.stateVersion = "22.11";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  time.hardwareClockInLocalTime = true; # otherwise dual-booted Windows has wrong time
}
# Neptunium specific hardware:1 ends here
