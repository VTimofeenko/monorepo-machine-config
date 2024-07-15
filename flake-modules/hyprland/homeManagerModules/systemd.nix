# home-manager module that makes certain services bind to the hyprland session
{
  pkgs,
  lib,
  selfPkgs,
  ...
}:
let
  selfPkgs' = selfPkgs.${pkgs.stdenv.system};
in
{
  # Constructs a set of services that will restart when hyprland-session is restarted
  systemd.user.services = lib.listToAttrs (
    map
      (serviceName: {
        name = serviceName;
        value = {
          Unit.BindsTo = [ "hyprland-session.target" ];
        };
      })
      [
        "swayidle"
        "swaync"
        "hyprland-language-switch-notifier"
        "hyprland-mode-switch-notifier"
        "hyprland-workspace-notifier"
        "swww"
      ]
  );
  wayland.windowManager.hyprland.extraConfig = "exec-once=${lib.getExe selfPkgs'.hyprland-maybe-restart-hyprland-session}";
}
