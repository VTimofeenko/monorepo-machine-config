/**
  Implements a service that restarts `zwave-js` every night. This is done to clear the send queue.

  https://github.com/zwave-js/zwave-js/pull/7743

  Remove when 25.11 lands.
*/
{ pkgs, ... }:

{
  systemd.services."restart-zwave-js" = {
    description = "Restart script for zwave-js.service";

    script = ''
      ${pkgs.systemd}/bin/systemctl restart zwave-js.service
    '';

    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };

  };

  systemd.timers."restart-zwave-js" = {
    description = "Daily 4:30 AM restart timer for zwave-js.service";

    timerConfig = {
      OnCalendar = "*-*-* 04:30:00";

      # No need to rerun this upon reboot
      Persistent = false;
      Unit = "restart-zwave-js.service";
    };

    # This ensures the timer is enabled on system startup.
    wantedBy = [ "timers.target" ];
  };
}
