# [[file:../../../new_project.org::*Uranium specific system][Uranium specific system:1]]
{ pkgs
, lib
, config
, my-sway-config
, my-doom-config
, ...
}@inputs:
{
  imports = [
    ../../de
    inputs.wg-namespace-flake.nixosModules.default
    ../../network/lan-wifi.nix
    # TODO: add optional phone network here commented

    ./hardware # (ref:uranium-hw-import)
  ];
}
# Uranium specific system:1 ends here
