# [[file:../../../new_project.org::*Hyprland language switch notifier][Hyprland language switch notifier:1]]
{ config, pkgs, lib, hyprland-language-switch-notifier, ... }:
{
  imports = [ hyprland-language-switch-notifier ];
  services.hyprland-language-switch-notifier.enable = true;
}
# Hyprland language switch notifier:1 ends here
