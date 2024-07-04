# Home-manager module to configure GTK theme
{ pkgs, ... }:
{
  catppuccin = {
    # enable = true;
    accent = "lavender";
    flavor = "macchiato";
  };
  gtk = {
    enable = true;
    catppuccin = {
      tweaks = [ "rimless" ];
      enable = true;
      accent = "lavender";
      flavor = "macchiato";
      size = "compact";
      icon.enable = true;
    };
    cursorTheme = {
      name = "macOS-Monterey-White";
      package = pkgs.apple-cursor;
    };
  };
}
