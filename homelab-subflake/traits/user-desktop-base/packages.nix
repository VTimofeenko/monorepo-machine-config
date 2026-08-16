/**
  General desktop applications that don't warrant their own trait.
*/
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    brave
  ];
}
