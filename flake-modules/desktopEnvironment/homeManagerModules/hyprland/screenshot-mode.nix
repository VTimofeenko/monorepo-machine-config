/**
  Home manager module that configures screenshot mode.
*/
{ pkgs, lib, ... }:
let
  settings = {
    modeEnter = "S";
    wholeScreen = "S";
    area = "A";
    window = "W";
  };

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
{
  wayland.windowManager.hyprland.myBinds =
    let
      srvLib = import ./binds/lib.nix { inherit lib; };
    in
    {
      "${srvLib.Control}+${settings.modeEnter}" = {
        mod = srvLib.mainMod;
        arg = "screenshot";
        description = "screenshot mode";

        "${settings.wholeScreen}" = {
          dispatcher = "exec";
          arg = "${grimblast} screen";
          description = "Whole screen";
        };

        "${settings.area}" = {
          dispatcher = "exec";
          arg = "${grimblast} area";
          description = "Selected area";
        };

        "${settings.window}" = {
          dispatcher = "exec";
          arg = "${grimblast} active";
          description = "Active window";
        };
      };
    };
}
