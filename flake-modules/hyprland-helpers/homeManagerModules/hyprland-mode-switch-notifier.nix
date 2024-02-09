# [[file:../../new_project.org::*hyprland mode switch notifier][hyprland mode switch notifier:1]]
# Home manager module to configure a user service that notifies when mode is switched
localFlake:
{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.services.hyprland-mode-switch-notifier;
  pkg = localFlake.packages.${pkgs.stdenv.hostPlatform.system}.hyprland-mode-notifier;
in
{
  options.services.hyprland-mode-switch-notifier = {
    enable = mkEnableOption "hyprland mode switch notifications";
  };
  config = mkIf cfg.enable {
    systemd.user.services.hyprland-mode-switch-notifier = {
      Unit = {
        Description = "Notifies user when mode is switched";
        BindsTo = [ "hyprland-session.target" ];
      };
      Service = {
        ExecStart = "${lib.getExe pkg}";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
# hyprland mode switch notifier:1 ends here
