/**
  Home-manager module that configures the app launcher.
*/
{ pkgs, lib, ... }:
{
  wayland.windowManager.hyprland.myBinds.R = {
    mod = "$mainMod";
    dispatcher = "exec";
    description = "Launch the launcher";
    arg = lib.getExe pkgs.centerpiece;
  };
}
