# [[file:../../../new_project.org::*Uranium specific system][Uranium specific system:1]]
{ lib, ... }:
{
  imports = [
    ../../../modules/de
    ./hardware # (ref:uranium-hw-import)
    # TODO: move to a separate module (impl + default)
    ./network-selector.nix
    ./user-stuff
  ];
  options.myMachines.uranium = {
    network = lib.mkOption {
      description = "Which network to use";
      type = lib.types.enum [
        "phy-lan"
        "eth"
        "adhoc-wifi"
      ];
      default = "phy-lan";
    };
  };
  config = {
    myMachines.uranium.network = "phy-lan";
    # To reset the volatile storage for journald. It breaks user's journald
    services.journald.extraConfig = lib.mkForce "";
    # a remnant from the past
    users.groups.uinput.gid = lib.mkForce 988;
    hardware = {
      # disable framework kernel module
      # https://github.com/NixOS/nixos-hardware/issues/1330
      framework.enableKmod = false;
    };
    virtualisation = {
      containers.enable = true;
      podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true; # Required for containers under podman-compose to be able to talk to each other.
      };
    };

    users.users.spacecadet.extraGroups = [ "podman" ];
    boot.kernelParams = [
      "amdgpu.mes=0" # Disable the Micro Engine Scheduler
      "amdgpu.vm_update_mode=3" # Force VM updates to CPU to improve recovery success
      "amdgpu.gpu_recovery=1" # Ensure the driver explicitly attempts recovery on hang
      "amdgpu.dcdebugmask=0x10" # Optional: Disable Panel Self Refresh (Prevents DE flickers/hangs)
    ];
  };

}
# Uranium specific system:1 ends here
