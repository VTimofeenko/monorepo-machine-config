{ pkgs, ... }:
{

  programs.sway.enable = true;

  xdg.portal =
    {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

}
