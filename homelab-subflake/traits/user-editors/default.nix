{ inputs, ... }:
{
  home-manager.users.spacecadet.imports = [
    ./neovim.nix
    ./file-associations.nix
    inputs.base.homeManagerModules.ideavim
    inputs.base.homeManagerModules.emacs
  ];
}
