# [[file:../../new_project.org::*User hyprland config][User hyprland config:1]]
# Home manaager module to configure hyprland
{ config, pkgs, lib, ... }:
let
  # Custom lib.nix for module-specific logic
  modLib = import ./lib.nix;

  cliphist = "${pkgs.cliphist}/bin/cliphist";

  utils = import ./utils.nix pkgs;

  launchShortcuts = {
    "Return" = "exec, ${pkgs.kitty}/bin/kitty";
    "E" = "exec, ${pkgs.libsForQt5.dolphin}/bin/dolphin";
    # Launches wofi with icons
    "R" = "exec, ${pkgs.wofi}/bin/wofi --show drun -I";
  };
  shiftLaunchShortcuts = {
    "grave" = "exec, ${lib.getExe utils.scratchpad-terminal}";
  };
  focusShortcuts =
    {
      "H" = "movefocus, l";
      "L" = "movefocus, r";
      "K" = "movefocus, u";
      "J" = "movefocus, d";
    };
  mergedConfig = builtins.concatStringsSep
    "\n"
    (
      builtins.attrValues
        (
          builtins.mapAttrs
            modLib.mkMainModBinding
            launchShortcuts
        )
      ++
      builtins.attrValues
        (
          builtins.mapAttrs
            modLib.mkMainModShiftBinding
            shiftLaunchShortcuts
        )
    );

in
{
  imports = [
    ./pyprland # (ref:pyprland-import)
  ];
  wayland.windowManager.hyprland =
    {
      enable = true;
      systemdIntegration = true;
      xwayland = {
        enable = true;
        hidpi = true;
      };
      nvidiaPatches = true;
      extraConfig =
        ''
          env = LIBVA_DRIVER_NAME,nvidia
          env = XDG_SESSION_TYPE,wayland
          env = GBM_BACKEND,nvidia-drm
          env = __GLX_VENDOR_LIBRARY_NAME,nvidia
          env = WLR_NO_HARDWARE_CURSORS,1

          # Some default env vars.
          env = XCURSOR_SIZE,24

          exec-once = systemd-cat --identifier=swaync ${pkgs.swaynotificationcenter}/bin/swaync
          # Clipboard manager
          exec-once = ${pkgs.wl-clipboard}/bin/wl-paste --watch ${cliphist} store

          # For all categories, see https://wiki.hyprland.org/Configuring/Variables/
          input {
              kb_layout = us,ru
              kb_options = grp:win_space_toggle

              follow_mouse = 1

              touchpad {
                  natural_scroll = false
                  disable_while_typing = true
              }

              sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
          }

          general {
              # See https://wiki.hyprland.org/Configuring/Variables/ for more

              gaps_in = 5
              gaps_out = 20
              border_size = 2
              col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
              col.inactive_border = rgba(595959aa)

              layout = dwindle
          }

          decoration {
              # See https://wiki.hyprland.org/Configuring/Variables/ for more

              rounding = 10
              blur = true
              blur_size = 3
              blur_passes = 1
              blur_new_optimizations = true

              drop_shadow = true
              shadow_range = 4
              shadow_render_power = 3
              col.shadow = rgba(1a1a1aee)
          }

          windowrulev2 = opacity 0.94 0.94,class:^(kitty)$

          animations {
              enabled = true

              # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

              bezier = myBezier, 0.05, 0.9, 0.1, 1.05

              animation = windows, 1, 7, myBezier
              animation = windowsOut, 1, 7, default, popin 80%
              animation = border, 1, 10, default
              animation = borderangle, 1, 8, default
              animation = fade, 1, 7, default
              animation = workspaces, 1, 6, default
          }

          dwindle {
              # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
              pseudotile = true # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
              preserve_split = true # you probably want this
          }

          master {
              # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
              new_is_master = true
          }

          gestures {
              workspace_swipe = true
          }

          binds {
              # TODO: Not sure
              pass_mouse_when_bound = true
              workspace_back_and_forth = true
              allow_workspace_cycles = true  # This is needed for workspace_back_and_forth behavior to be similar to sway
          }

          # Example windowrule v1
          # windowrule = float, ^(kitty)$
          # Example windowrule v2
          # windowrulev2 = float,class:^(kitty)$,title:^(kitty)$
          # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more


          # See https://wiki.hyprland.org/Configuring/Keywords/ for more
          $mainMod = SUPER

          # Move focus with mainMod + arrow keys
          bind = $mainMod, H, movefocus, l
          bind = $mainMod, L, movefocus, r
          bind = $mainMod, K, movefocus, u
          bind = $mainMod, J, movefocus, d

          # Move current window to target split area
          bind = $mainMod SHIFT, H, movewindow, l
          bind = $mainMod SHIFT, L, movewindow, r
          bind = $mainMod SHIFT, K, movewindow, u
          bind = $mainMod SHIFT, J, movewindow, d

          # Switch workspaces with mainMod + [0-9]
          bind = $mainMod, 1, workspace, 1
          bind = $mainMod, 2, workspace, 2
          bind = $mainMod, 3, workspace, 3
          bind = $mainMod, 4, workspace, 4
          bind = $mainMod, 5, workspace, 5
          bind = $mainMod, 6, workspace, 6
          bind = $mainMod, 7, workspace, 7
          bind = $mainMod, 8, workspace, 8
          bind = $mainMod, 9, workspace, 9
          bind = $mainMod, grave, workspace, previous

          # Move active window to a workspace with mainMod + SHIFT + [0-9]
          bind = $mainMod SHIFT, 1, movetoworkspacesilent, 1
          bind = $mainMod SHIFT, 2, movetoworkspacesilent, 2
          bind = $mainMod SHIFT, 3, movetoworkspacesilent, 3
          bind = $mainMod SHIFT, 4, movetoworkspacesilent, 4
          bind = $mainMod SHIFT, 5, movetoworkspacesilent, 5
          bind = $mainMod SHIFT, 6, movetoworkspacesilent, 6
          bind = $mainMod SHIFT, 7, movetoworkspacesilent, 7
          bind = $mainMod SHIFT, 8, movetoworkspacesilent, 8
          bind = $mainMod SHIFT, 9, movetoworkspacesilent, 9

          # Scroll through existing workspaces with mainMod + scroll
          bind = $mainMod, mouse_down, workspace, e+1
          bind = $mainMod, mouse_up, workspace, e-1

          # Move/resize windows with mainMod + LMB/RMB and dragging
          bindm = $mainMod, mouse:272, movewindow
          bindm = $mainMod, mouse:273, resizewindow

          bind = $mainMod SHIFT, T, togglefloating
          bind = $mainMod SHIFT, Q, killactive
          bind = $mainMod, F, fullscreen  # Fullscreen
          bind = $mainMod, O, fullscreen, 1  # fOcus

          bind = $mainMod CTRL, Q, exec, ${pkgs.swaylock}/bin/swaylock -fF -k -c 000000
          bind = $mainMod CTRL, M, exit,
          # Toggle notification pane
          bind = $mainMod CTRL, N, exec, ${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw
          # Clipboard history toggle
          bind = $mainMod CTRL, C, exec, ${cliphist} list | ${pkgs.wofi}/bin/wofi --show dmenu | ${cliphist} decode | ${pkgs.wl-clipboard}/bin/wl-copy
        '' + mergedConfig;
    };
}
# User hyprland config:1 ends here
