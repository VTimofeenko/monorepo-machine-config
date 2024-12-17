/**
  Home-manager module that configures the app launcher.
*/
{
  lib,
  config,
  ...
}:
{
  wayland.windowManager.hyprland.settings."$launcher" =
    assert lib.assertMsg config.programs.centerpiece.enable "centerpiece should be enabled";
    "centerpiece";

  wayland.windowManager.hyprland.myBinds.R = {
    mod = "$mainMod";
    dispatcher = "exec";
    description = "Launch the launcher";
    arg = "$launcher";
  };
}
