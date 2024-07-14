{ pkgs, ... }:
{
  xdg.portal = {
    enable = true;
    config.common.default = [ "hyprland" ];
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
