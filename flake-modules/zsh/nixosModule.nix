# NixOS module that configures zsh
{ self }:
{ pkgs, lib, config, ... }:
let
  inherit (self) inputs;
  commonSettings = import ./common.nix {
    inherit pkgs config;
    pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.system};
  };
  inherit (lib) concatMapStringsSep;
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = lib.mkForce false;
    histFile = "$XDG_CACHE_HOME/zsh_history";
    histSize = 10000;
    interactiveShellInit = commonSettings.initExtra
      + commonSettings.completionInit
      + (with commonSettings.plugins;
      ''
        fpath=(${baseDir} $fpath)
      ''
      + concatMapStringsSep "\n" (plugin: "autoload -Uz ${plugin}.zsh && ${plugin}.zsh") list)
      + "\n"
      +
      # Allows searching for completion
      ''
        zstyle ':completion:*:*:*:default' menu yes select search
      ''
    ;
    inherit (commonSettings) shellAliases;
    syntaxHighlighting = {
      enable = true;
    };

    autosuggestions.enable = true;

  };
  programs.starship.enable = true;
  environment = { inherit (commonSettings) variables; };
  environment.systemPackages = commonSettings.packages;
}
