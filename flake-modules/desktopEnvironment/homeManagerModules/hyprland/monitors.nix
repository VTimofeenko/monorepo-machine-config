# Hyprland monitor config
{ lib, ... }:
let
  srvLib = import ./binds/lib.nix { inherit lib; };

  inherit (srvLib) mainMod Shift Alt Hyper;
in
{
  wayland.windowManager.hyprland.myBinds = {
    "Tab" = {
      mod = mainMod;
      dispatcher = "focusmonitor";
      arg = "+1";
      description = "focus the next monitor";
    };
    "${Shift}+Tab" = {
      mod = mainMod;
      dispatcher = "movewindow";
      arg = "mon:+1";
      description = "move current window to the next monitor";
    };
    "${Shift}+${Alt}+Tab" = {
      mod = mainMod;
      dispatcher = "movecurrentworkspacetomonitor";
      arg = "+1";
      description = "move current workpace to the next monitor";
    };
    "${Hyper}+Tab" = {
      mod = mainMod;
      dispatcher = "swapactiveworkspaces";
      arg = "current +1";
      description = "swap workspaces with the next monitor";
    };
  };

  wayland.windowManager.hyprland.settings.monitor = lib.mkDefault (
    builtins.trace
      ''You probably want to override the
      `wayland.windowManager.hyprland.settings.monitor` setting.

      It's currently set to no value, which will probably work at first but the
      resolution can be pretty bad.

      See https://wiki.hyprland.org/Configuring/Monitors/
      ''
      { }
  );
}
