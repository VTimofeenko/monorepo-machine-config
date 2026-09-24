{
  lib,
  ...
}:
{
  # Boot/filesystems/GPU
  imports = [
    ./bootloader.nix
    ./filesystems.nix
    ./nvidia.nix
  ];

  # Misc
  system.stateVersion = "22.11";
  hardware = {
    cpu.amd.updateMicrocode = lib.mkForce true;
    enableRedistributableFirmware = true;
  };
  time.hardwareClockInLocalTime = true; # otherwise dual-booted Windows has wrong time
}
