/**
  Workspaces configuration for hyprland. Includes keybinds and general settings.

  This is a Home manager module.
*/
{ lib, ... }:
let
  srvLib = import ./binds/lib.nix { inherit lib; };

  inherit (srvLib) mainMod Shift;

  /**
    produces mod+1 -> switch to ws 1 binds.

    Output format conforms with listToAttrs function (name/value attrset)
  */
  mkSwitchBind = key: {
    name = key;
    value = {
      mod = mainMod;
      dispatcher = "workspace";
      arg = key;
      description = "switch to workspace '${key}'";
    };
  };

  mkMoveWindowBind =
    key:
    mkSwitchBind key
    |> lib.flip lib.recursiveUpdate {
      name = "${Shift}+${key}";
      value.dispatcher = "movetoworkspacesilent";
      value.description = "move window to workspace '${key}'";
    };

  defaultWorkspaces = lib.genList (x: x + 1) 9 |> map builtins.toString;
in
{
  wayland.windowManager.hyprland = {
    # Setup binds
    myBinds = lib.traceVal (
      defaultWorkspaces
      |> map (wsNum: [
        # Switch workspaces with mainMod + [0-9]
        (mkSwitchBind wsNum)
        # Move active window to a workspace
        (mkMoveWindowBind wsNum)
      ])
      |> lib.flatten
      |> builtins.listToAttrs
      # add mod+` to switch back
      |> lib.mergeAttrs {
        ${srvLib."`"} = {
          mod = mainMod;
          dispatcher = "workspace";
          arg = "previous";
          description = "switch to previous workspace";
        };
      }
    );

    settings.binds = {
      # Given two workspaces ("1" and "2")
      # If I am on 1st:
      # mod+2 => switch to 2nd
      # mod+2 (again) => switch to 1st
      workspace_back_and_forth = true;
      # Main use case -- switch back and forth using mod+grave
      allow_workspace_cycles = true;
    };

    # Mouse swipe = swipe workspace. Occasionally I use it.
    settings.gestures.workspace_swipe = true;
  };
}
