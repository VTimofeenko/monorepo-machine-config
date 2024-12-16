{ lib, ... }:
let
  moduleList = [
    ./focus-switching.nix
  ];

  srvLib = import ../lib.nix { inherit lib; };

  passLib = modPath: import modPath { inherit srvLib; };
in
{
  # This is effectively "take all modules here, apply special library from one
  # place and import them under a specific attribute".
  #
  # The benefit of this approach:
  # * I don't need to repeat "myBinds" in all nested modules
  # * I don't need to keep importing the srvLib in every module.
  wayland.windowManager.hyprland.myBinds = moduleList |> (map passLib) |> lib.mkMerge;
}
