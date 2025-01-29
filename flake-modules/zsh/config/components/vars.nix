{ lib, pkgs, ... }:
let
  inherit (lib) getExe;
  settings.variables = {
    EDITOR = "nvim";
    FZF_CTRL_T_COMMAND = "${getExe pkgs.fd} .";
    FZF_ALT_C_COMMAND = "${getExe pkgs.fd} -t d .";
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
    DOTFILES_REPO_LOCATION = "$HOME/code/literate-machine-config";
  };
in
{
  nixosModule = {
    environment = {
      inherit (settings) variables;
    };
  };
  homeManagerModule = {
    programs.zsh.sessionVariables = settings.variables;
  };
}
