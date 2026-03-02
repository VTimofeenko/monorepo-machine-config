{ pkgs, ... }:
{
  imports = [ ./base-mod.nix ];

  # Utilities for developing/inspecting nix
  home.packages = [
    pkgs.nix-melt
    pkgs.nix-top
    # TODO: migrate `nopt-parser` here from zsh?
  ];
}
