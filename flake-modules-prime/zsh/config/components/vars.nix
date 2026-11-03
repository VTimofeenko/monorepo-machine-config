{ lib, pkgs, ... }:
let
  inherit (lib) getExe;
  settings.variables = {
    EDITOR = "nvim";
    FZF_CTRL_T_COMMAND = "${getExe pkgs.fd} .";
    FZF_ALT_C_COMMAND = "${getExe pkgs.fd} -t d .";
    FZF_CTRL_R_OPTS = "--with-nth 2.."; # Hide history event number in ctrl-R; selection still carries it
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
    DOTFILES_REPO_LOCATION = "$HOME/code/literate-machine-config/homelab-subflake";
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
