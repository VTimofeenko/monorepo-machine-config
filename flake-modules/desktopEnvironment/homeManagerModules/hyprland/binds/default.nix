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
  imports = [
    ./impl.nix
    ./binds
  ];
}
