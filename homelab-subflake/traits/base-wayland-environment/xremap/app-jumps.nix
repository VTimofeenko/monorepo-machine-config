/**
  Contains xremap side of application jumping.

  The main logic is that Caps Lock when pressed alone emits Escape.

  If Caps Lock is pressed with, say, 'E', focus switches to Emacs.
*/
let
  settings.appMap = {
    # E is for Emacs
    e = "Emacs";
    # B is for browser
    b = "firefox";
    # T is for terminal
    t = "kitty";
    # TODO: `W` is for Whiteboard
    # TODO: `S` if for scratch?

  };
in
{ lib, ... }:
{
  services.xremap.config = {
    virtual_modifiers = [ "F18" ];

    modmap = [
      {
        # Global remap Caps Lock to emit `F18` when held
        name = "Global";
        remap."CapsLock" = {
          held = "F18";
          # Single press of Caps Lock = "escape"
          alone = "Esc";
          alone_timeout_millis = 250;
        };
      }
    ];

    keymap = [
      {
        name = "Remap hyper key";
        # Needs explicit bindings it seems. Maybe accept `F18` as modifier in Hyprland?
        # Basically produces bindings like "`F18-e`" = "SHIFT-C-M-SUPER-e"
        # These are later handled by hyprland
        remap = lib.mapAttrs' (
          name: _: lib.nameValuePair "F18-${name}" "SHIFT-C-M-SUPER-${name}"
        ) settings.appMap;
      }
    ];
  };
}
