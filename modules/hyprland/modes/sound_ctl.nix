# [[file:../../../new_project.org::*Sound_ctl][Sound_ctl:1]]
mkModeBinding:
{ pkgs, config, lib, ... }:
let
  execWpctl = "exec, ${pkgs.wireplumber}/bin/wpctl";
in
mkModeBinding
  "SUPERCTRL,M"
  "sound_ctl"
  ''
    binde=, XF86AudioLowerVolume, ${execWpctl} set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ -10%+
    binde=, XF86AudioRaiseVolume, ${execWpctl} set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 10%+
    binde=, F2, ${execWpctl} set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ -10%+
    binde=, F3, ${execWpctl} set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 10%+
    # Silence the output
    bind=, s, ${execWpctl} set-sink-mute @DEFAULT_AUDIO_SINK@ toggle
    bind=, F1, ${execWpctl} set-sink-mute @DEFAULT_AUDIO_SINK@ toggle
    bind=, XF86AudioMute, ${execWpctl} set-sink-mute @DEFAULT_AUDIO_SINK@ toggle
    # Mute the mic
    bind=, m, ${execWpctl} set-source-mute @DEFAULT_AUDIO_SOURCE@ toggle
    bind=, XF86AudioMicMute, ${execWpctl} set-source-mute @DEFAULT_AUDIO_SOURCE@ toggle
  ''
# Sound_ctl:1 ends here
