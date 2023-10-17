# [[file:../../new_project.org::*hyprland workspace notifier][hyprland workspace notifier:1]]
# Home manager module to configure a user service that notifies when workspace was switched
{ localFlake, withSystem }:
{ pkgs, lib, self, config, ... }:
with lib;
let
  pkgName = "hyprland-workspace-notifier";

  cfg = config.services.${pkgName};
  pkg = localFlake.packages.${pkgs.stdenv.hostPlatform.system}.${pkgName};
in
{
  options.services.${pkgName} = {
    enable = mkEnableOption "hyprland workspace change notifications";
  };
  config = mkIf cfg.enable {
    systemd.user.services.${pkgName} = {
      Unit = {
        Description = "Notifies user when the workspace is switched";
        BindsTo = [ "hyprland-session.target" ];
      };
      Service = {
        ExecStart = "${lib.getExe pkg}";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
# hyprland workspace notifier:1 ends here
