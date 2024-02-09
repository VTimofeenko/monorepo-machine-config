# [[file:../../../new_project.org::*Uranium hyprland config][Uranium hyprland config:1]]
_: {
  wayland.windowManager.hyprland = {
    extraConfig = ''
      monitor=eDP-1,2256x1504@60,0x0,1
      # Touchpad that pretends to be a mouse?
      device:frmw0001:00-32ac:0006-consumer-control-1 {
        sensitivity = 1.0
      }
    '';
  };
}
# Uranium hyprland config:1 ends here
