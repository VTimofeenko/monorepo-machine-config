{ pkgs, ... }:
{
  xdg.portal = {
    config = {
      common = {
        "org.freedesktop.impl.portal.FileChooser" = [
          "kde"
          "gtk"
        ];
      };
      niri = {
        "org.freedesktop.impl.portal.FileChooser" = [
          "kde"
          "gtk"
        ];
      };
    };
    extraPortals = [
      pkgs.kdePackages.xdg-desktop-portal-kde
    ];
  };

  environment.sessionVariables = {
    GTK_USE_PORTAL = "1";
  };
}
