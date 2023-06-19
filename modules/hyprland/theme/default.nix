# [[file:../../../new_project.org::*Hyprland theme][Hyprland theme:1]]
{ pkgs, ... }:
let
  # Script from sway wiki to set needed variables
  set_gsettings = pkgs.writeShellScript "set_gsettings" ''
    PATH=${pkgs.glib}/bin:$PATH

    config="''${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini"
    if [ ! -f "$config" ]; then exit 1; fi

    gnome_schema="org.gnome.desktop.interface"
    gtk_theme="$(grep 'gtk-theme-name' "$config" | sed 's/.*\s*=\s*//')"
    icon_theme="$(grep 'gtk-icon-theme-name' "$config" | sed 's/.*\s*=\s*//')"
    cursor_theme="$(grep 'gtk-cursor-theme-name' "$config" | sed 's/.*\s*=\s*//')"
    font_name="$(grep 'gtk-font-name' "$config" | sed 's/.*\s*=\s*//')"
    gsettings set "$gnome_schema" gtk-theme "$gtk_theme"
    gsettings set "$gnome_schema" icon-theme "$icon_theme"
    gsettings set "$gnome_schema" cursor-theme "$cursor_theme"
    gsettings set "$gnome_schema" font-name "$font_name"
  '';
in
rec {
  gtk = {
    enable = true;
    theme = {
      name = "Materia";
      package = pkgs.materia-theme;
    };
    iconTheme = {
      name = "Papirus-Dark-Maia";
      package = pkgs.papirus-maia-icon-theme;
    };
    cursorTheme = {
      name = "Quintom_Ink";
      package = pkgs.quintom-cursor-theme;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-icon-theme-name = "Papirus-Dark-Maia";
      # gtk-cursor-theme-name = "Quintom_Ink";
    };
  };
  qt = {
    enable = true;
    platformTheme = "gtk";
    style.name = "breeze";
  };
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      cursor-theme = "Quintom_Ink";
    };
  };
  xdg.systemDirs.data = [
    "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
    "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
  ];
  wayland.windowManager.hyprland.extraConfig =
    ''
      exec-once=${set_gsettings}
      exec-once=hyprctl setcursor ${gtk.cursorTheme.name} 24

      # Taken from home manager qt config's home.sessionVariables
      env=QT_QPA_PLATFORMTHEME,${if qt.platformTheme == "gtk" then
        "gtk2"
      else if qt.platformTheme == "qtct" then
        "qt5ct"
      else
        qt.platformTheme}
      env=QT_STYLE_OVERRIDE,${qt.style.name}
    '';

  # Installs adwaita as the fallback
  home.packages = [ pkgs.gnome.gnome-themes-extra ];
}
# Hyprland theme:1 ends here
