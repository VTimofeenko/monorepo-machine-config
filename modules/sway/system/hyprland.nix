{ config, pkgs, lib, ... }:
{
  programs.hyprland.enable = true;
  environment.systemPackages = [ pkgs.kitty ]; # BUG: remove later
}
