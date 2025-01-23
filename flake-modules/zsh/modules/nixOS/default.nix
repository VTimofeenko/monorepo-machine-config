# NixOS module that configures zsh
{ self, ... }:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  commonSettings = import ../common { inherit pkgs config self; };
  inherit (lib) concatMapStringsSep;
in
{
  imports = [
    (import ../../config { inherit lib pkgs; }).nixosModule
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = lib.mkForce false;
    interactiveShellInit =
      commonSettings.initExtra
      + (
        with commonSettings.myPlugins;
        ''
          fpath=(${baseDir} $fpath)
        ''
        + concatMapStringsSep "\n" (plugin: "autoload -Uz ${plugin}.zsh && ${plugin}.zsh") list
      )
      + "\n";
    inherit (commonSettings) shellAliases;
    syntaxHighlighting = {
      enable = true;
    };

    autosuggestions.enable = true;
  };
  programs.starship.enable = true;
  environment = {
    inherit (commonSettings) variables;
  };
  environment.systemPackages = commonSettings.packages;
}
