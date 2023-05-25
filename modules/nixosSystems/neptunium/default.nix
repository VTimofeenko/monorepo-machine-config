# [[file:../../../new_project.org::*Neptunium specific system][Neptunium specific system:1]]
{ pkgs, config, lib, ... }@inputs:
{
  imports = [
    ./access.nix # (ref:neptunium-access-import)
    ./hardware # (ref:neptunium-hardware-import)
    ../../de # (ref:desktop-env-import)
  ];
}
# Neptunium specific system:1 ends here
