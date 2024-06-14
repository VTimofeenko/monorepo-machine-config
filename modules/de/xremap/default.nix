# [[file:../../../new_project.org::*Xremap][Xremap:1]]
{ xremap-flake, ... }:
{
  imports = [
    xremap-flake.nixosModules.default
    ./shortcuts.nix
  ];

  services.xremap = {
    withWlroots = true;
    userName = "spacecadet";
    serviceMode = "user";
    watch = true;
  };
}
# Xremap:1 ends here
