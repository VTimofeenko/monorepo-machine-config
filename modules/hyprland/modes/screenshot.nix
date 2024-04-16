/**
  Screenshot making mode
*/
mkModeBinding:
{ pkgs, lib, ... }:
let
  grimblast-wrapper = pkgs.writeShellApplication {
    name = "grimblast-wrapper";
    runtimeInputs = [
      pkgs.grimblast
      pkgs.libnotify
    ];
    text = ''
      ${lib.getExe pkgs.grimblast} copysave "$1" "$HOME/Pictures/Screenshots/$1-$(date +'%F-%T').png"
      hyprctl dispatch submap reset
      notify-send --icon screenshot "'$1' screenshot saved"
    '';
  };
  grimblast = lib.getExe grimblast-wrapper;
in
# I don't care about empty screenshots if esc is pressed
mkModeBinding "SUPERSHIFT,S" "Screenshot" ''
  # f = full screen
  binde = , f, exec, ${grimblast} screen
  # a = area
  binde = , a, exec, ${grimblast} area
  # w = active window
  binde = , w, exec, ${grimblast} active
''
