{ lib, pkgs, ... }:
let
  inherit (lib)
    mapAttrs
    foldr
    mergeAttrs
    mapAttrs'
    nameValuePair
    ;
  bindLib = import ./lib.nix { inherit lib; };
  inherit (bindLib)
    arrowKeys
    Shift
    mkOneToTen
    mainMod
    LMB
    RMB
    ;
in
{
  wayland.windowManager.hyprland = {
    settings = {
      binds = {
        pass_mouse_when_bound = true;
        workspace_back_and_forth = true;
        allow_workspace_cycles = true; # This is needed for workspace_back_and_forth behavior to be similar to sway
      };

      "$mainMod" = "SUPER";
    };
    myBinds = foldr mergeAttrs [
      # Simple focus movement
      (mapAttrs (_: arg: {
        mod = mainMod;
        dispatcher = "movefocus";
        inherit arg;
      }) arrowKeys)

      # Move window to target split area
      (mapAttrs (_: arg: {
        mod = "${mainMod} ${Shift}";
        dispatcher = "movewindow";
        inherit arg;
      }) arrowKeys)

      # Navigate to numbered workspace
      (mapAttrs (_: arg: {
        mod = mainMod;
        dispatcher = "workspace";
        inherit arg;
      }) mkOneToTen)

      # Jump back
      {
        "grave" = {
          mod = mainMod;
          dispatcher = "workspace";
          arg = "previous";
        };
      }

      # Move window to numbered workspace by shift+mainmod+<number>
      (mapAttrs' (
        n: arg:
        nameValuePair "${Shift}+${n}" {
          mod = "${mainMod}";
          dispatcher = "movetoworkspacesilent";
          inherit arg;
        }
      ) mkOneToTen)

      # Mouse window moving/resizing
      {
        "${LMB}" = {
          bindType = "bindm";
          mod = "${mainMod} ${Shift}";
          dispatcher = "movewindow";
        };
        "${RMB}" = {
          bindType = "bindm";
          mod = "${mainMod} ${Shift}";
          dispatcher = "movewindow";
        };
      }

      # Misc
      {
        T = {
          mod = "${mainMod} ${Shift}";
          dispatcher = "togglefloating";
        };
        Q = {
          mod = "${mainMod} ${Shift}";
          dispatcher = "killactive";
        };
        F = {
          mod = mainMod;
          dispatcher = "fullscreen";
        };
        O = {
          mod = mainMod;
          dispatcher = "fullscreen";
          arg = "1";
        };
      }

      # Leader mode
      {
        "Alt_R" = {
          arg = "leader";

          # Toggle mode
          T = {
            N = {
              dispatcher = "exec";
              arg = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
            };
            # TODO: Clipboard history

            # ${cliphist} list | ${pkgs.wofi}/bin/wofi --show dmenu | ${cliphist} decode | ${pkgs.wl-clipboard}/bin/wl-copy
          };
        };
      }


    ];
  };

  imports = [ ./impl.nix ];
}
