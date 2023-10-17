# [[file:../../../new_project.org::*Xremap][Xremap:1]]
{ pkgs, lib, config, ... }@inputs:
{
  imports = [
    inputs.xremap-flake.nixosModules.default
    ./shortcuts.nix
  ];

  services.xremap = {
    withWlroots = true;
    userName = "spacecadet";
    serviceMode = "user";
  };
}
# Xremap:1 ends here
