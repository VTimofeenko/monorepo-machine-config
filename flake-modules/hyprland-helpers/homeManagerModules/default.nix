# The module that imports other hyprland helpers and mass-enables them
localFlake:
{ lib, config, ... }:
let
  cfg = config.services.hyprland-helpers;
  inherit (lib) mkEnableOption mkIf mkOption;
in
{
  imports = with localFlake.homeManagerModules; [
    hyprland-language-switch-notifier
    hyprland-mode-switch-notifier
    hyprland-workspace-switch-notifier
  ];
  options.services.hyprland-helpers = {
    enable = mkEnableOption "hyprland mode switch notifications";
    target = mkOption { default = "hyprland-session.target"; };
  };
  config = mkIf cfg.enable {
    services = rec {
      hyprland-language-switch-notifier = {
        enable = true;
        inherit (cfg) target;
      };
      hyprland-mode-switch-notifier = hyprland-language-switch-notifier;
      hyprland-workspace-notifier = hyprland-language-switch-notifier;
    };
  };
}
