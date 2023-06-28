# [[file:../../../new_project.org::*Audio][Audio:1]]
{ pkgs, config, lib, ... }:
{
  wayland.windowManager.hyprland.extraConfig =
    lib.mkAfter
      ''
        binde=, XF86AudioLowerVolume, exec, ${pkgs.wireplumber}/bin/wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 10%-
        binde=, XF86AudioRaiseVolume, exec, ${pkgs.wireplumber}/bin/wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 10%+
        binde=, F2, exec, ${pkgs.wireplumber}/bin/wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 10%-
        binde=, F3, exec, ${pkgs.wireplumber}/bin/wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 10%+
      '';
}
# Audio:1 ends here
