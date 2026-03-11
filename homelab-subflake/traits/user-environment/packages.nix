{ pkgs, ... }:
{
  home.packages = [
    pkgs.calibre
    pkgs.pavucontrol
    pkgs.blueman
    pkgs.libreoffice
    pkgs.brave
    pkgs.gthumb
  ];
}
