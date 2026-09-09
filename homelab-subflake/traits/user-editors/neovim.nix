{ inputs, ... }:
{
  imports = [
    inputs.base.homeManagerModules.vim
    inputs.base.homeManagerModules.vidir-img
  ];

  programs.vidir-img.enable = true;

  programs.myNeovim = {
    enable = true;
    type = "max";
  };
}
