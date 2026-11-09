{ config, pkgs, ... }:
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

  # When niri runs as a systemd user unit, `niri-session` skips its
  # `import-environment`, so the portal never sees this login-shell var and
  # loads no backends (no FileChooser/Settings). Pin it on the unit directly.
  systemd.user.services.xdg-desktop-portal.environment = {
    inherit (config.environment.sessionVariables) NIX_XDG_DESKTOP_PORTAL_DIR;
  };
}
