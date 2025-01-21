/**
  Configures backlight control, integrated with `swayosd`.

  Originally using `brightnessctl`.

  TODO: make brightness four discrete values instead of the 10% step
*/
{ pkgs, lib, ... }:
let
  settings.brightnessStepPct = 10;
in
{
  wayland.windowManager.hyprland.myBinds = rec {
    XF86MonBrightnessDown = {
      dispatcher = "exec";
      description = "Lower brightness";
      arg =
        [
          "${pkgs.swayosd}/bin/swayosd-client"
          "--brightness=-${toString settings.brightnessStepPct}"
        ]
        |> lib.concatStringsSep " ";
    };
    XF86MonBrightnessUp = {
      dispatcher = "exec";
      description = "Raise brightness";
      arg =
        [
          "${pkgs.swayosd}/bin/swayosd-client"
          "--brightness=+${toString settings.brightnessStepPct}"
        ]
        |> lib.concatStringsSep " ";
    };
    F7 = XF86MonBrightnessDown;
    F8 = XF86MonBrightnessUp;
  };
}
