{ inputs, ... }:
{
  imports = [
    inputs.base.homeManagerModules.vim
  ];
  programs.myNeovim = {
    enable = true;
    type = "max";
  };
}
