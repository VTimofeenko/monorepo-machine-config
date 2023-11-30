# [[file:../../../new_project.org::*Brightness][Brightness:1]]
{ pkgs, lib, ... }:
{
  wayland.windowManager.hyprland.extraConfig =
    lib.mkAfter
      ''
        binde=, XF86MonBrightnessDown, exec, ${lib.getExe pkgs.brightnessctl} set 10%-
        binde=, F7, exec, ${lib.getExe pkgs.brightnessctl} set 10%-
        binde=, XF86MonBrightnessUp, exec, ${lib.getExe pkgs.brightnessctl} set +10%
        binde=, F8, exec, ${lib.getExe pkgs.brightnessctl} set +10%
      '';
}
# Brightness:1 ends here
