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
        "wifi-lan"
        "eth"
        "adhoc-wifi"
      ];
      default = "wifi-lan";
    };
  };
  config = {
    myMachines.uranium.network = "wifi-lan";
    # To reset the volatile storage for journald. It breaks user's journald
    services.journald.extraConfig = lib.mkForce "";
    # a remnant from the past
    users.groups.uinput.gid = lib.mkForce 988;
  };
}
# Uranium specific system:1 ends here
