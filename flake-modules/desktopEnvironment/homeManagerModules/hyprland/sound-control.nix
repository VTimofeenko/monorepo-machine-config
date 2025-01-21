/**
  Configures backlight control, integrated with `swayosd`.

  Originally using `wireplumber` like so:
  ```
          "${pkgs.wireplumber}/bin/wpctl"
          "set-volume"
          "-l"
          "1.5"
          "@DEFAULT_AUDIO_SINK@"
  ```
*/
{ pkgs, lib, ... }:
let
  settings.volumeStepPct = 10;
in
{
  wayland.windowManager.hyprland.myBinds = rec {
    XF86AudioMute = {
      dispatcher = "exec";
      description = "Toggle output mute";
      arg =
        [
          "${pkgs.swayosd}/bin/swayosd-client"
          "--output-volume=mute-toggle"
        ]
        |> lib.concatStringsSep " ";
    };
    XF86AudioLowerVolume = {
      dispatcher = "exec";
      description = "Lower volume";
      arg =
        [
          "${pkgs.swayosd}/bin/swayosd-client"
          "--output-volume=-${toString settings.volumeStepPct}"
        ]
        |> lib.concatStringsSep " ";
    };
    XF86AudioRaiseVolume = {
      dispatcher = "exec";
      description = "Raise volume";
      arg =
        [
          "${pkgs.swayosd}/bin/swayosd-client"
          "--output-volume=+${toString settings.volumeStepPct}"
        ]
        |> lib.concatStringsSep " ";
    };
    F2 = XF86AudioLowerVolume;
    F3 = XF86AudioRaiseVolume;
  };
}
