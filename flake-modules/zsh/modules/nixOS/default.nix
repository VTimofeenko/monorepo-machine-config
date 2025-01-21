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
  programs.zsh = {
    enable = true;
    enableCompletion = lib.mkForce false;
    histFile = "$XDG_CACHE_HOME/zsh_history";
    histSize = 10000;
    interactiveShellInit =
      commonSettings.initExtra
      + commonSettings.completionInit
      + (
        with commonSettings.myPlugins;
        ''
          fpath=(${baseDir} $fpath)
        ''
        + concatMapStringsSep "\n" (plugin: "autoload -Uz ${plugin}.zsh && ${plugin}.zsh") list
      )
      + "\n"
      + (concatMapStringsSep "\n" (
        plugin: "source ${plugin.src}/${plugin.file}"
      ) commonSettings.packagePlugins);
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

  # Add completions
  environment.pathsToLink = [ "/share/zsh" ];
}
