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
  };

}
# Uranium specific system:1 ends here
