/* File that produces a module to be imported by the flake module */
{ tmuxConfBuilder }:
{ pkgs, lib, ... }:
let
  inherit (tmuxConfBuilder { inherit (pkgs) lib; inherit pkgs; }) tmuxConf;
in
{
  programs.tmux = {
    enable = true;
    /* Commented out, since set in the mkTmuxConf function */
    # terminal = "tmux-256color";
    keyMode = "vi";
    baseIndex = 1;
    escapeTime = 1;
    extraConfig = tmuxConf;
  };
}
