# [[file:../../../new_project.org::*Uranium specific system][Uranium specific system:1]]
{ lib
, config
, ...
}@inputs:
{
  imports = [
    ../../de
    inputs.wg-namespace-flake.nixosModules.default
    ./hardware # (ref:uranium-hw-import)
    ./network-selector.nix
  ];
  options.myMachines.uranium = {
    network = lib.mkOption {
      description = "Which network to use";
      type = lib.types.enum [ "wifi-lan" "eth" "adhoc-wifi" ];
      default = "wifi-lan";
    };
  };
  config = {
    myMachines.uranium.network = "wifi-lan";
  };
}
# Uranium specific system:1 ends here
