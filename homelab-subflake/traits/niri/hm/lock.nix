{ pkgs, lib, ... }:
let
  niriMsg = "${lib.getExe pkgs.niri} msg action";
  lockCmd = "${niriMsg} switch-layout 0 && ${lib.getExe pkgs.swaylock} --daemonize --show-failed-attempts --color 000000";
in
{
  xdg.configFile."niri/lock.kdl".text = ''
    binds {
        Mod+Ctrl+Q hotkey-overlay-title="Lock the Screen" { spawn "loginctl" "lock-session"; }
    }
  '';

  services.swayidle = {
    enable = true;
    systemdTarget = "niri.service";
    events = {
      after-resume = "${niriMsg} power-on-monitors";
      lock = lockCmd;
      before-sleep = lockCmd;
    };
    timeouts = [
      {
        timeout = 300;
        command = "${niriMsg} power-off-monitors";
      }
      {
        timeout = 303;
        command = lockCmd;
      }
    ];
  };
}
