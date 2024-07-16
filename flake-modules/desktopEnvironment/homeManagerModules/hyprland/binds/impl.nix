/*
  Module that provides a way to set Hyprland key bindings as a nested Nix attribute set.

  Example:

    wayland.windowManager.hyprland.myBinds = {
      "H" = {
        mod = "$mainMod";
        dispatcher = "movefocus";
        arg = "l";
        description = "move focus to the left";
      };
      "L" = {
        mod = "$mainMod";
        dispatcher = "movefocus";
        arg = "r";
        description = "move focus to the right";
      };

      "Alt_R" = {
        arg = "leader";
        description = "Leader mode";

        "H" = {
          mod = "$mainMod";
          dispatcher = "movefocus";
          arg = "r";
          description = "move focus to the right";
        };
      };
    };

  Results in the Hyprland config:

    bind = , Alt_R, submap, leader
    bind = $mainMod, H, movefocus, r
    bind = , escape, submap, reset
    submap = reset

    bind = $mainMod, H, movefocus, l
    bind = $mainMod, L, movefocus, r

    TODO: https://config.phundrak.com/hyprland.html#keybindings
    looks luke nested submaps work <=> they have "submap = $name" line first and "submap reset" needs to be one and only one after all of them
*/
{ lib, config, ... }:
let
  inherit (lib)
    mkOption
    types
    concatStringsSep
    pipe
    mapAttrs
    flip
    removeAttrs
    hasAttr
    mergeAttrs
    filter
    hasInfix
    splitString
    last
    subtractLists
    toUpper
    assertMsg
    elem
    unique
    concat
    id
    ;

  cfg = config.wayland.windowManager.hyprland.myBinds;

  # Custom binding type
  # TODO: Rewrite this type

  # binding = types.submodule {
  #   options = {
  #     # TODO: type = [bind, binde, whatever]

in
#     mod = mkOption {
#       type = types.nullOr types.str;
#       default = null;
#       description = "Modifier key for the binding";
#     };
#     # https://wiki.hyprland.org/Configuring/Dispatchers/
#     dispatcher = mkOption {
#       type = types.enum [
#         "exec"
#         "execr"
#         "pass"
#         "sendshortcut"
#         "killactive"
#         "closewindow"
#         "workspace"
#         "movetoworkspace"
#         "movetoworkspacesilent"
#         "togglefloating"
#         "setfloating"
#         "settiled"
#         "fullscreen"
#         "fakefullscreen"
#         "dpms"
#         "pin"
#         "movefocus"
#         "movewindow"
#         "swapwindow"
#         "centerwindow"
#         "resizeactive"
#         "moveactive"
#         "resizewindowpixel"
#         "movewindowpixel"
#         "cyclenext"
#         "swapnext"
#         "tagwindow"
#         "focuswindow"
#         "focusmonitor"
#         "splitratio"
#         "toggleopaque"
#         "movecursortocorner"
#         "movecursor"
#         "renameworkspace"
#         "exit"
#         "forcerendererreload"
#         "movecurrentworkspacetomonitor"
#         "focusworkspaceoncurrentmonitor"
#         "moveworkspacetomonitor"
#         "swapactiveworkspaces"
#         "bringactivetotop"
#         "alterzorder"
#         "togglespecialworkspace"
#         "focusurgentorlast"
#         "togglegroup"
#         "changegroupactive"
#         "focuscurrentorlast"
#         "lockgroups"
#         "lockactivegroup"
#         "moveintogroup"
#         "moveoutofgroup"
#         "movewindoworgroup"
#         "movegroupwindow"
#         "denywindowfromgroup"
#         "setignoregrouplock"
#         "global"
#         "submap"
#         "event"
#       ];
#       description = "Dispatcher to use for the binding";
#     };
#     arg = mkOption {
#       type = types.str;
#       description = "Argument for the dispatcher";
#     };
#     description = mkOption {
#       type = types.str;
#       default = "";
#       description = ''
#         Description for the keybind.
#         Not used in the hyprland config'';
#     };
#   };
# };
{
  # Interface
  options.wayland.windowManager.hyprland.myBinds = mkOption {
    type = types.attrsOf types.attrs; # (types.either binding types.attrs);
    default = { };

    example = {
      # turns into "bind = $mainMod, H, movefocus, l"
      H = {
        mod = "$mainMod";
        dispatcher = "movefocus";
        arg = "l";
      };
      # turns into "bind = ,Alt_R,submap,leader"
      Alt_R = {
        # turns into "bind = , P, exec, ls" inside the submap
        P = {
          dispatcher = "exec";
          arg = "ls";
          description = "Run ls";
        };
      };
    };

    description = ''
      Attrset representing tree of keyboard bindings.

      Nested attrsets map to submaps.'';
  };

  # Implementation
  config.wayland.windowManager.hyprland.extraConfig =
    let
      renderSingleBind =
        n: v:
        let
          hasDesc =
            assert assertMsg (
              !(hasInfix "," (v.description or ""))
            ) "Bind description should not contain a comma";
            hasAttr "description" v;

          flags' = v.flags or [ ];
          bindType = pipe flags' [
            (if hasDesc then concat [ "d" ] else id)
            unique
            (concatStringsSep "")
            (x: "bind${x}")
          ];

          nameHasMod = hasInfix "+" n;

          checkAndNormalizeModifier =
            x:
            pipe x [
              toUpper
              (
                y:
                assert assertMsg (elem y [
                  "SHIFT"
                  "CTRL"
                  "ALT"
                ]) "Unknown modifier: ${y}";
                y
              )
            ];

          n' = pipe n [
            (splitString "+")
            last
          ];
          mod' = concatStringsSep " " (
            [ v.mod or "" ]
            ++ (
              if nameHasMod then
                pipe n [
                  (splitString "+")
                  (subtractLists [ n' ])
                  (map checkAndNormalizeModifier)
                ]
              else
                [ ]
            )
          );
        in
        pipe
          [
            mod'
            n'
            (v.description or null)
            v.dispatcher
            (v.arg or null)
          ]
          [
            (filter (x: x != null)) # Remove nulls from list
            (map toString) # Normalize as strings
            (concatStringsSep ", ")
            (x: "${bindType} = ${x}")
          ];

      removeMetaArgs = flip removeAttrs [
        "dispatcher"
        "arg"
        "description"
        "mod"
      ];

      recursiveRender =
        attrset:
        pipe attrset [
          (mapAttrs (
            n: v:
            let
              # Detect potential submap entrypoint
              v' =
                if
                  # "dispatcher" is not expliticly specified
                  !hasAttr "dispatcher" v
                  &&
                    # Has subkeys
                    builtins.length (
                      pipe v [
                        removeMetaArgs
                        builtins.attrValues
                      ]
                    ) > 0
                then
                  v // { dispatcher = "submap"; }
                else
                  v;
            in
            if v'.dispatcher == "submap" && v'.arg != "reset" then
              (pipe v' [
                # Drop meta arguments
                removeMetaArgs

                # Append "exit submap by esc"
                (flip mergeAttrs {
                  "escape" = {
                    mod = "";
                    dispatcher = "submap";
                    arg = "reset";
                    description = "exit submap";
                  };
                })

                # Recurse, render sub-submaps
                recursiveRender

                # Prepend the key to enter the submap
                # and append the "submap = reset" so hyprland knows the submap definition is over
                (x: ''
                  ${renderSingleBind n v'}
                  ${x}
                  submap = reset
                '')
              ])
            else
              renderSingleBind n v'
          ))
          builtins.attrValues
          (concatStringsSep "\n")
        ];
    in
    recursiveRender cfg;
}
