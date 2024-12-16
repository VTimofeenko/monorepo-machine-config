{ lib, ... }:
let
  bindLib = import ./lib.nix { inherit lib; };
  inherit (bindLib)
    arrowKeys
    Shift
    Super
    Control
    mkOneToTen
    mainMod
    LMB
    RMB
    ;
in
{
  wayland.windowManager.hyprland.settings."$mainMod" = Super;
  wayland.windowManager.hyprland.myBinds = {
    Return = {
      mod = mainMod;
      dispatcher = "exec";
      description = "Launch terminal emulator";
      arg = "kitty";
    };
    # Sample mode binding
    # "${Control}+Q" = {
    #   arg = "leader";
    #   T = {
    #     arg = "other_leader";
    #     N = {
    #       dispatcher = "exec";
    #       arg = "kitty";
    #     };
    #   };
    # };
  };
  imports = [
    ./impl.nix
    ./binds
  ];
}
