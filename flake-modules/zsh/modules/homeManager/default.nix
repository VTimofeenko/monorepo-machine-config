# Home manager module that configures zsh
{ self, ... }:
{
  pkgs,
  config,
  lib,
  ...
}:
let
  commonSettings = import ../common { inherit pkgs config self; };
in
{
  imports = [
    (import ../../config { inherit lib pkgs self; }).homeManagerModule
  ];

  programs = {
    zsh = {
      enable = true;
      # Type directory name -> cd there
      autocd = true;
      # Start in VI insert mode
      defaultKeymap = "viins";
      # Move the dotfiles to .config -- unclutter home dir
      dotDir = ".config/zsh";
    };
  };
}
