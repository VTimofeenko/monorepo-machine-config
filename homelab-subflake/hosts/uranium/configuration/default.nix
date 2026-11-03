/**
  Framework 13 (AMD 7040), daily driver.
*/
{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./hardware.nix
    ./framework.nix
    ./3d-print
    ./gamemode.nix
    ./wifi-tdls-disable.nix
  ];

  # Roams onto public networks: nothing listens, not even for kdeconnect/syncthing/localsend
  networking.firewall = {
    allowedTCPPorts = lib.mkForce [ ];
    allowedTCPPortRanges = lib.mkForce [ ];
    allowedUDPPorts = lib.mkForce [ ];
    allowedUDPPortRanges = lib.mkForce [ ];
  };
  environment.systemPackages = [ pkgs.wpa_supplicant_gui ];

  # To reset the volatile storage for journald. It breaks user's journald
  services.journald.extraConfig = lib.mkForce "";
  # a remnant from the past
  users.groups.uinput.gid = lib.mkForce 988;

  # Cross-compilation setup
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  boot.kernelParams = [
    "amdgpu.mes=0" # Disable the Micro Engine Scheduler
    "amdgpu.vm_update_mode=3" # Force VM updates to CPU to improve recovery success
    "amdgpu.gpu_recovery=1" # Ensure the driver explicitly attempts recovery on hang
    "amdgpu.dcdebugmask=0x10" # Optional: Disable Panel Self Refresh (Prevents DE flickers/hangs)
  ];

  home-manager.users.spacecadet =
    { pkgs, ... }:
    {
      # Existing profile lives here, `user-browser` defaults to XDG location
      programs.firefox.configPath = lib.mkForce ".mozilla/firefox";
      imports = [ inputs.base.homeManagerModules.zellij ];
      home.packages = [ pkgs.calibre ];
    };
}
