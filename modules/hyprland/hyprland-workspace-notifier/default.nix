# [[file:../../../new_project.org::*Hyprland workspace notifier][Hyprland workspace notifier:1]]
args@{ config, pkgs, lib, ... }:
let
  srvName = "hyprland-workspace-notifier";
in
{
  imports = [ args.${srvName} ];
  services.${srvName}.enable = true;
}
# Hyprland workspace notifier:1 ends here
