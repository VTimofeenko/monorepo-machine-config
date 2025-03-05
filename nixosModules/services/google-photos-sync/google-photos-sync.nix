/**
  This service mount Google Photos as a local directory using `rclone`.

  The backup is done of `media/by-month` as suggested here:

  https://rclone.org/googlephotos
*/
{
  pkgs,
  lib,
  config,
  ...
}:
let
  srvName = "google-photos-sync";
in
{
  systemd.services.${srvName} = {
    enable = true;
    description = "Sync Google Photos to a local directory";
    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "google-photos-sync";
      ExecStart =
        ''
          env
          set -x
          ${pkgs.rclone |> lib.getExe} sync \
            --config $CREDENTIALS_DIRECTORY/config \
            photos:media/by-month \
            $STATE_DIRECTORY
        ''
        |> pkgs.writeShellScript "runme";
      # Hardening
      PrivateTmp = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectSystem = "strict";
      RemoveIPC = true;
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      LoadCredential = [ "config:${config.age.secrets.photos-mount-config.path}" ];
    };
  };

  systemd.timers.${srvName} = {
    timerConfig = {
      OnCalendar = "*-*-* 08,14,18,23:00"; # Doing this too often triggers 429 errors, this seems like a reasonable compromise
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };
}
