{ osConfig, ... }:
let
  inherit (osConfig.my-colortheme.hex) semantic raw;
in
{
  wayland.windowManager.hyprland.settings.general = {
    col.active_border = "rgba(${semantic.activeFrameBorder}ff) rgba(${semantic.inactiveFrameBorder.hex}00) 45deg";
    col.inactive_border = "rgba(${semantic.inactiveFrameBorder}aa)";
  };
  wayland.windowManager.hyprland.settings.decoration = {
    "col.shadow" = "rgba(${raw.bg-dim}ee)";
  };
}
