# [[file:../../../new_project.org::*Hyprland mode switch notifier][Hyprland mode switch notifier:1]]
{ config, pkgs, lib, hyprland-mode-switch-notifier, ... }:
{
  imports = [ hyprland-mode-switch-notifier ];
  services.hyprland-mode-switch-notifier.enable = true;
}
# Hyprland mode switch notifier:1 ends here
