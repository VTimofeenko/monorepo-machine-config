{ pkgs, lib, ... }:
let
  srvLib = import ./binds/lib.nix { inherit lib; };
  inherit (srvLib) Control;
in
{
  wayland.windowManager.hyprland.myBinds."${Control}+T"."N" = {
    description = "Toggle notification pane";
    dispatcher = "exec";
    arg = "${pkgs.swaynotificationcenter}/bin/swaync-client --toggle-panel --skip-wait";
  };
}
