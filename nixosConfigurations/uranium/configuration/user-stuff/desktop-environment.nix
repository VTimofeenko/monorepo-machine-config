# Home-manager module that configures uranium-specific desktop environment tweaks
{ config, lib, ... }:
{
  wayland.windowManager.hyprland.settings =
    assert lib.assertMsg config.wayland.windowManager.hyprland.enable
      "hyprland needs to be enabled and under correct attribute";
    {
      monitor = "eDP-1,2256x1504@60,0x0,1"; # This is the built in monitor
    };
}
