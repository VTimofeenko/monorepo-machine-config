# [[file:../../../new_project.org::*Uranium specific system][Uranium specific system:1]]
{ lib
, config
, ...
}@inputs:
{
  imports = [
    ../../de
    inputs.wg-namespace-flake.nixosModules.default
    # TODO: add optional phone network here commented
    # ../../network/ethernet.nix
    # ../../network/public-firewall.nix
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
    myMachines.uranium.network = "eth";
  };
}
# Uranium specific system:1 ends here
