{ pkgs, lib, ... }:
let
  inherit (lib.homelab) getHostInNetwork;
in
{
  systemd.services.reboot-outlet = {
    description = "Reboot the outlet just in case";
    script =
      let
        kasaCli = lib.getExe' pkgs.python3Packages.python-kasa "kasa";
        outletIp = (getHostInNetwork "patio-outlet" "lan").ipAddress;
      in
      ''
        ${kasaCli} --host ${outletIp} reboot
      '';
  };

  systemd.timers.reboot-outlet = {
    description = "Timer to reboot the outlet";
    timerConfig.OnCalendar = "*-*-* 03:00:00";
    wantedBy = [ "multi-user.target" ];
  };
}
