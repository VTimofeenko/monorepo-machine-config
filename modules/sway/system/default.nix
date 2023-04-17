{ pkgs, ... }:
{
  imports =
    [
      # ./base-settings.nix
      ./greeter.nix
      ./hyprland.nix
      # ./additional-packages.nix
      # TODO: xremap also goes here
    ];
}
