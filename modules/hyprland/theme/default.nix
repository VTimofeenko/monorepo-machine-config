/* Home-manager module to configure GTK theme */
{ pkgs
, ...
}:
{
  gtk = {
    enable = true;
    cursorTheme = {
      name = "macOS-Monterey-White";
      package = pkgs.apple-cursor;
    };
    iconTheme = {
      name = "Pop";
      package = pkgs.pop-icon-theme;
    };
    theme = {
      name = "Catppuccin-Macchiato-Compact-Lavender-Dark";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "lavender" ];
        size = "compact";
        tweaks = [ "rimless" ];
        variant = "macchiato";
      };
    };
  };
}
