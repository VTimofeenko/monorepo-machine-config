# Hyprland monitor config
{ lib, ... }:
{
  wayland.windowManager.hyprland.settings.monitor = lib.mkDefault (
    builtins.trace
      ''You probably want to override the
      `wayland.windowManager.hyprland.settings.monitor` setting.

      It's currently set to no value, which will probably work at first but the
      resolution can be pretty bad.

      See https://wiki.hyprland.org/Configuring/Monitors/
      ''
      { }
  );
}
