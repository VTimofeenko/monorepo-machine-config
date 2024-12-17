/**
 Home manager module that sets up:
  - binding to switch language
  - service that notifies of language change
  - hyprland settings for language input

  Implementation note: this module uses one of my hyprland helpers to switch
  languages.

  hyprland-switch-lang-on-xremap behaves similar to a combination of
  hyprctl switchxkblayout and hyprctl dispatch input:kb_layout.
  By default it cycles the layouts, but it also has set_en flag (used in
  locking) which sets English layout when the session is locked.
*/
{ pkgs, lib, ... }:
{
  wayland.windowManager.hyprland.settings = {
    # Sets all keyboard layouts on all input devices
    # This is necessary for lang switch to work at all
    input.kb_layout = "us,ru";

    # This setting is necessary so that certain shortcuts (ctrl-w) as an
    # example work on non-US languages
    # TODO: move to an option, neptunium will have it different
    device = {
      name = ["at-translated-set-2-keyboard"];
      kb_layout = "us";
    };
  };

  # Switch languages by super+space
  # I may revisit that and repurpose super+space to something that is used more
  # often
  wayland.windowManager.hyprland.myBinds.Space = {
    mod = "$mainMod";
    dispatcher = "exec";
    description = "Switch to next input language";
    arg = lib.getExe pkgs.hyprland-switch-lang-on-xremap;
  };
}
