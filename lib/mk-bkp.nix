/**
  Function that produces a module implementing backups.

  If the `localDB` variable is true, restic will perform a local database dump
  and back it up too.
*/
{
  paths,
  exclude ? [ ],
  schedule ? "daily",
  localDB ? false, # If set to true, adds `pg_dumpall` script to backup the result of the DB dump
  serviceName,
}:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (config.networking) hostName;
in
{
  imports = [ lib.localLib.mkHealthCheckModules ];
  services.restic.backups = {
    "${serviceName}-localbackup" = {
      initialize = true;
      passwordFile = config.age.secrets."${serviceName}-bkp-password".path;
      inherit exclude;
      paths =
        paths ++ (lib.optional localDB "/run/restic-backups-${serviceName}-localbackup/pg_dumpall.sql");

      # This is a bit brittle as it hardcodes paths
      backupPrepareCommand =
        if localDB then
          ''/run/wrappers/bin/sudo -u postgres '/run/current-system/sw/bin/pg_dumpall' > "$RUNTIME_DIRECTORY/pg_dumpall.sql"''
        else
          null; # As the default

      repository = "rest:https://${lib.homelab.getServiceFqdn "restic-server"}/${hostName}/${serviceName}";
      timerConfig.OnCalendar = schedule;
      package = (
        ''
          export RESTIC_REST_PASSWORD=$(cat $CREDENTIALS_DIRECTORY/restic_server_password)
          ${lib.getExe pkgs.restic} $@
        ''
        |> pkgs.writeShellScriptBin "restic"
      );
    };
  };

  systemd.services."restic-backups-${serviceName}-localbackup" = {
    onFailure = [ "ping-healthchecks@${serviceName}-local-backup:failure.service" ];
    onSuccess = [ "ping-healthchecks@${serviceName}-local-backup:success.service" ];
    wants = [ "ping-healthchecks@${serviceName}-local-backup:start.service" ];

    serviceConfig = {
      Environment = [ "RESTIC_REST_USERNAME=${hostName}" ];
      LoadCredential = [
        "restic_server_password:${config.age.secrets.restic-client-htpasswd.path}"
      ];
    };
  };
}
