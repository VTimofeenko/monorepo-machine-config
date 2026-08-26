{ pkgs, ... }:
{
  # Explicit cursor theme+size everywhere (XCURSOR_THEME/XCURSOR_SIZE env
  # vars, GTK settings, Xresources) instead of relying on per-toolkit
  # defaults, which diverge: native-Wayland GTK apps and Xwayland/X11 apps
  # picked different implicit sizes, making the pointer normal-sized in
  # Xwayland (e.g. Emacs) but huge in native Wayland windows. Mirrored in
  # ./config.kdl's `cursor` block for niri's own compositor-drawn cursor.
  home.pointerCursor = {
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
}
