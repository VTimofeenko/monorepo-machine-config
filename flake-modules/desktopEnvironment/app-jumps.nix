/**
  Home manager and NixOS modules that configures xremap and hyprland to enable
  pressing capslock+$key or hyper+$key to jump to specific apps.
*/
let
  appMap = {
    # E is for Emacs
    e = "Emacs";
    # B is for browser
    b = "firefox";
  };

in
{
  nixosModule =
    { lib, ... }:
    {
      services.xremap.config = {
        virtual_modifiers = [ "F18" ];

        modmap = [
          {
            # Global remap CapsLock to emit F18 when held
            name = "Global";
            remap."CapsLock" = {
              held = "F18";
              # Single press of CapsLock = "escape"
              # TODO: figure out a way to separate this; this setting does not
              # belong here. Unfortunately if the 'alone' part is not
              # specified, the config validation fails.
              #
              # One way is to create an intermittent option for remapping
              # capslock. The option can be merged using NixOS modules and turn
              # into modmap in impl.
              alone = "Esc";
              alone_timeout_millis = 250;
            };
          }
        ];

        keymap = [
          {
            name = "Remap hyper key";
            # Needs explicit bindings it seems. Maybe accept F18 as modifier in Hyprland?
            # Basically produces bindings like "F18-e" = "SHIFT-C-M-SUPER-e"
            # These are later handled by hyprland
            remap = lib.mapAttrs' (name: _: lib.nameValuePair "F18-${name}" "SHIFT-C-M-SUPER-${name}") appMap;
          }
        ];
      };
    };
  homeManagerModule =
    { srvLib, ... }:
    let
      inherit (srvLib) lib Hyper mainMod;
    in
    {
      wayland.windowManager.hyprland.myBinds = lib.mapAttrs' (
        name: value:
        lib.nameValuePair "${Hyper}+${name}" {
          mod = mainMod;
          dispatcher = "focuswindow";
          arg = "^(${value})$";
          description = "Focus '${value}' window";
        }
      ) appMap;
    };
}
