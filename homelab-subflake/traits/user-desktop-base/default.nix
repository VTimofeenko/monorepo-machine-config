{ inputs, ... }:
{
  home-manager.users.spacecadet.imports = [
    ./file-associations.nix
    ./packages.nix
    inputs.base.homeManagerModules.kitty
  ];
}
