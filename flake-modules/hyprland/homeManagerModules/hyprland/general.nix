_: {
wayland.windowManager.hyprland = {
  settings.general = {
    gaps_in = 5;
    gaps_out = 20;
    border_size = 2;
    layout = "dwindle";
  };
  extraConfig = ''
    windowrule = float,xdg-desktop-portal-gtk
  '';
};
}
