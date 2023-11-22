# The module that imports other hyprland helpers and mass-enables them
localFlake:
{ lib, config, ... }:
let
  cfg = config.services.hyprland-helpers;
  inherit (lib) mkEnableOption mkIf;
in
{
  imports = with localFlake.homeManagerModules; [
    hyprland-language-switch-notifier
    hyprland-mode-switch-notifier
    hyprland-workspace-switch-notifier
  ];
  options.services.hyprland-helpers = {
    enable = mkEnableOption "hyprland mode switch notifications";
  };
  config = mkIf cfg.enable {
    services = {
      hyprland-language-switch-notifier.enable = true;
      hyprland-mode-switch-notifier.enable = true;
      hyprland-workspace-notifier.enable = true;
    };
  };
}
