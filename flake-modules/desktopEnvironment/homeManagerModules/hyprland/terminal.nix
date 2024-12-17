/**
  Home-manager module that configures the terminal X desktop environment.
*/
{ pkgs, lib, ... }:
{
  wayland.windowManager.hyprland.settings."$term" = lib.getExe pkgs.kitty;

  wayland.windowManager.hyprland.myBinds.Return = {
    mod = "$mainMod";
    dispatcher = "exec";
    description = "Launch terminal emulator";
    arg = "$term";
  };

  # TODO: floating terminal
}
