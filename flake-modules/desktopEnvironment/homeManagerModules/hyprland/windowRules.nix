/**
  Home-manager module that configures per-window rules that don't have a better place to live.
*/
{
  wayland.windowManager.hyprland.settings = {
    "$pinentry" = "^(pinentry-qt)$";
    "windowrule" = [
      "float,$pinentry"
      "float,xdg-desktop-portal-gtk"
      "float,title:^Open File.*"
      "size 25% 20%,$pinentry"
      "center,$pinentry"
      "stayfocused,$pinentry"
      "dimaround,$pinentry"
    ];
  };
}
