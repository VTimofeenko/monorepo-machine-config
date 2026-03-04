# File that produces a module to be imported by the flake module
{ tmuxConfBuilder }:
{ pkgs, lib, ... }:
let
  inherit (tmuxConfBuilder { inherit pkgs lib; })
    tmuxConf
    ;
in
{
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    baseIndex = 1;
    escapeTime = 1;
    extraConfig = tmuxConf;
  };
}
