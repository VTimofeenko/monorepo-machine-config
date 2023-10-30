# [[file:../../../new_project.org::*Lockscreen][Lockscreen:1]]
{ pkgs, lib, selfPkgs, ... }:
let
  lockCmd = "${setEnCmd} && ${lib.getExe pkgs.swaylock} --daemonize --show-failed-attempts --show-keyboard-layout --color 000000";
  # NOTE: may be pulling in hyprctl from nixpkgs and not the flake
  hyprctlCmd = "${pkgs.hyprland}/bin/hyprctl";

  selfPkgs' = selfPkgs.${pkgs.stdenv.system};
  setEnCmd = "${lib.getExe selfPkgs'.hyprland-switch-lang-on-xremap} set_en";
in
{
  wayland.windowManager.hyprland.extraConfig =
    lib.mkAfter
      ''
        misc {
          mouse_move_enables_dpms = true
          key_press_enables_dpms = true
        }

        bind = $mainMod CTRL, Q, exec, ${setEnCmd} && loginctl lock-session
      '';
  services.swayidle = {
    enable = true;
    systemdTarget = "hyprland-session.target";
    events = [
      { event = "after-resume"; command = "${hyprctlCmd} dispatch dpms on"; }
      { event = "before-sleep"; command = lockCmd; }
      { event = "lock"; command = lockCmd; }
    ];
    timeouts = [
      { timeout = 300; command = "${hyprctlCmd} dispatch dpms off"; }
      { timeout = 303; command = lockCmd; }
    ];
  };
}
# Lockscreen:1 ends here
