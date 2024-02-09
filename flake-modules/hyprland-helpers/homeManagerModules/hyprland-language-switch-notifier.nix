# [[file:../../new_project.org::*hyprland language switch notifier][hyprland language switch notifier:1]]
# Home manager module to configure a user service that notifies when language was switched
localFlake:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.hyprland-language-switch-notifier;
  pkg = localFlake.packages.${pkgs.stdenv.hostPlatform.system}.hyprland-lang-notifier;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.services.hyprland-language-switch-notifier = {
    enable = mkEnableOption "hyprland language switch notifications";
  };
  config = mkIf cfg.enable {
    systemd.user.services.hyprland-language-switch-notifier = {
      Unit = {
        Description = "Notifies user when language is switched";
        BindsTo = [ "hyprland-session.target" ];
      };
      Service = {
        ExecStart = "${lib.getExe pkg}";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
# hyprland language switch notifier:1 ends here
