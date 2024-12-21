# [[file:../../new_project.org::*hyprland workspace notifier][hyprland workspace notifier:1]]
# Home manager module to configure a user service that notifies when workspace was switched
localFlake:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  pkgName = "hyprland-workspace-notifier";

  cfg = config.services.${pkgName};
  pkg = localFlake.packages.${pkgs.stdenv.hostPlatform.system}.${pkgName};
  inherit (lib) mkEnableOption mkIf mkOption;
in
{
  options.services.${pkgName} = {
    enable = mkEnableOption "hyprland workspace change notifications";
    target = mkOption { default = "hyprland-session.target"; };
  };
  config = mkIf cfg.enable {
    systemd.user.services.${pkgName} = {
      Unit = {
        Description = "Notifies user when the workspace is switched";
        BindsTo = [ cfg.target ];
      };
      Service = {
        ExecStart = "${lib.getExe pkg}";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
# hyprland workspace notifier:1 ends here
