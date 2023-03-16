{ pkgs, ... }:
{
  imports =
    [
      ./base-settings.nix
      ./greeter.nix
      # ./additional-packages.nix
      # TODO: xremap also goes here
    ];
}
