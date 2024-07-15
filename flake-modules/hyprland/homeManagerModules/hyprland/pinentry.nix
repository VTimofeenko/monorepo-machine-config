_: {
  wayland.windowManager.hyprland.extraConfig = ''
    $pinentry = ^(pinentry-qt)$
    windowrule = float,$pinentry
    windowrule = size 25% 20%,$pinentry
    windowrule = center,$pinentry
    windowrule = stayfocused,$pinentry
    windowrule = dimaround,$pinentry
  '';
}
