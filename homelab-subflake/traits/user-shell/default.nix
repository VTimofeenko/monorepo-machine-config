{ inputs, ... }:
{
  home-manager.users.spacecadet.imports = [
    ./broot.nix
    ./ripgrep.nix
    ./gh.nix
    inputs.base.homeManagerModules.git
    inputs.base.homeManagerModules.zsh
  ];
}
