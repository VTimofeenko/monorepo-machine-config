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
  localOnly ? false, # If set to true, do not store backups remotely
  backupName ? null,
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

  actualBackupName = if builtins.isNull backupName then serviceName else backupName;

  # Define retention policy
  pruneOpts = [
    "--keep-daily 7"
    "--keep-weekly 4"
    "--keep-monthly 6"
  ];

  dumpScript =
    if localDB then
      ''
        ${pkgs.util-linux}/bin/logger "Starting DB dump for ${serviceName}"
        ${lib.getExe pkgs.sudo} -u postgres ${config.services.postgresql.package}/bin/pg_dumpall | ${lib.getExe pkgs.gzip} > "$RUNTIME_DIRECTORY/pg_dumpall.sql.gz"
        ${pkgs.util-linux}/bin/logger "DB dump done"
      ''
    else
      null;

  dumpFile = if localDB then "pg_dumpall.sql.gz" else null;
in
{
  imports = [
    lib.localLib.mkHealthCheckModules
    {

      /**
        Local backup is done to an instance of restic server running in the lab.

        The mechanism is REST:
        https://restic.readthedocs.io/en/latest/030_preparing_a_new_repo.html#rest-server
      */
      services.restic.backups = {
        "${serviceName}-localbackup" = {
          inherit exclude paths pruneOpts;
          timerConfig.OnCalendar = schedule;
          # If `localDB` is set, `dynamicFilesFrom` will list the dump
          dynamicFilesFrom = if localDB then "ls $RUNTIME_DIRECTORY/${dumpFile}" else null;

          backupPrepareCommand = dumpScript;

          repository = "rest:https://${lib.homelab.getServiceFqdn "restic-server"}/${hostName}/${actualBackupName}";
          package = (
            ''
              export RESTIC_REST_PASSWORD=$(cat $CREDENTIALS_DIRECTORY/restic_server_password)
              ${lib.getExe pkgs.restic} $@
            ''
            |> pkgs.writeShellScriptBin "restic"
          );
          initialize = true;
          passwordFile = config.age.secrets."${serviceName}-bkp-password".path;
        };
      };

      systemd.services."restic-backups-${actualBackupName}-localbackup" = {
        onFailure = [ "ping-healthchecks@${actualBackupName}-local-backup:failure.service" ];
        onSuccess = [ "ping-healthchecks@${actualBackupName}-local-backup:success.service" ];
        wants = [ "ping-healthchecks@${actualBackupName}-local-backup:start.service" ];

        serviceConfig = {
          Environment = [ "RESTIC_REST_USERNAME=${hostName}" ];
          LoadCredential = [
            "restic_server_password:${config.age.secrets.restic-client-htpasswd.path}"
          ];
        };
      };
    }
    (lib.optionalAttrs (!localOnly) {
      /**
        Remote backup is done to rsync.net by default. The implementation is
        largely the same as local backup, except for special handling of the SSH
        key.

        The mechanism is sFTP:
        https://restic.readthedocs.io/en/latest/030_preparing_a_new_repo.html#sftp
      */
      services.restic.backups."${serviceName}-rsync-net-backup" = {
        inherit exclude paths pruneOpts;

        # If `localDB` is set, `dynamicFilesFrom` will list the dump
        dynamicFilesFrom = if localDB then "ls $RUNTIME_DIRECTORY/${dumpFile}" else null;

        repository = "sftp:${(lib.homelab.getService "rsync-net").settings.sftpConnectString}:${actualBackupName}";
        timerConfig.OnCalendar = schedule;

        backupPrepareCommand = dumpScript;

        # The package override ensures that the service has access to the SSH key
        # when it's running
        package =
          let
            userKnownHostsFile =
              lib.homelab.getServiceConfig "rsync-net"
              |> builtins.getAttr "knownFingerPrint"
              |> pkgs.writeText "rsync-net-fingerprint";
          in
          (
            ''
              ${lib.getExe pkgs.restic} \
              -o sftp.args="-i $CREDENTIALS_DIRECTORY/rsync-net-ssh-key -o UserKnownHostsFile=${userKnownHostsFile}" \
              $@
            ''
            |> pkgs.writeShellScriptBin "restic"
          );
        initialize = true;
        passwordFile = config.age.secrets."${serviceName}-bkp-password".path;
      };

      systemd.services."restic-backups-${actualBackupName}-rsync-net-backup" = {
        onFailure = [ "ping-healthchecks@${actualBackupName}-rsync-net-backup:failure.service" ];
        onSuccess = [ "ping-healthchecks@${actualBackupName}-rsync-net-backup:success.service" ];
        wants = [ "ping-healthchecks@${actualBackupName}-rsync-net-backup:start.service" ];

        serviceConfig.LoadCredential = [ "rsync-net-ssh-key:${config.age.secrets.rsync-net-ssh.path}" ];
      };
    })
  ];
}

