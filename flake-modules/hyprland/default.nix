# Flake-module entry point for my hyprland config.
# { self, ... }:
_: {
  flake = {
    nixosModules.myHyprland = import ./nixosModules { };
    homeManagerModules.myHyprland = { };
  };
}
