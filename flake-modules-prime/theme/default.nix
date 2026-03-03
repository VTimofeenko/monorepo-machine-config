# Flake module that produces NixOS and Home-manager modules with my theme
{ lib, ... }:
let
  module = import ./module.nix { inherit theme; };
  theme = (import ./data.nix) |> (import ./lib.nix { inherit lib; }).mkTheme;
in
{
  flake = {
    nixosModules.my-theme = module;
    homeManagerModules.my-theme = module;

    data.my-colortheme = theme;
  };
}
