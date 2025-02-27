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

  /**
    Local backup is done to an instance of restic server running in the lab.

    The mechanism is REST:
    https://restic.readthedocs.io/en/latest/030_preparing_a_new_repo.html#rest-server
  */
  services.restic.backups = {
    "${serviceName}-localbackup" = {
      inherit exclude paths;
      timerConfig.OnCalendar = schedule;
      # If localDB is set, dynamicFilesFrom will list the dump
      dynamicFilesFrom =
        if localDB then "ls $RUNTIME_DIRECTORY/pg_dumpall.sql" else null # Option default
      ;
      backupPrepareCommand =
        # Dump the database if localDB is true.
        #
        # I only use PostgreSQL in my homelab, so there's no need to handle
        # anything else
        if localDB then
          ''
            /run/current-system/sw/bin/logger "Starting DB dump"
            /run/wrappers/bin/sudo -u postgres '/run/current-system/sw/bin/pg_dumpall' > "$RUNTIME_DIRECTORY/pg_dumpall.sql"
            /run/current-system/sw/bin/logger "DB dump done:"
            /run/current-system/sw/bin/logger "$(ls $RUNTIME_DIRECTORY)"
          ''
        else
          null; # As the default

      repository = "rest:https://${lib.homelab.getServiceFqdn "restic-server"}/${hostName}/${serviceName}";
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

  /**
    Remote backup is done to rsync.net by default. The implementation is
    largely the same as local backup, except for special handling of the SSH
    key.

    The mechanism is sFTP:
    https://restic.readthedocs.io/en/latest/030_preparing_a_new_repo.html#sftp
  */
  services.restic.backups."${serviceName}-rsync-net-backup" = {
    inherit exclude paths;
    # If localDB is set, dynamicFilesFrom will list the dump
    dynamicFilesFrom =
      if localDB then "ls $RUNTIME_DIRECTORY/pg_dumpall.sql" else null # Option default
    ;
    repository = "sftp:${(lib.homelab.getService "rsync-net").settings.sftpConnectString}:${serviceName}";
    timerConfig.OnCalendar = schedule;
    backupPrepareCommand =
      # Dump the database if localDB is true.
      #
      # I only use PostgreSQL in my homelab, so there's no need to handle
      # anything else
      if localDB then
        ''
          /run/current-system/sw/bin/logger "Starting DB dump"
          /run/wrappers/bin/sudo -u postgres '/run/current-system/sw/bin/pg_dumpall' > "$RUNTIME_DIRECTORY/pg_dumpall.sql"
          /run/current-system/sw/bin/logger "DB dump done:"
          /run/current-system/sw/bin/logger "$(ls $RUNTIME_DIRECTORY)"
        ''
      else
        null; # As the default

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

  systemd.services."restic-backups-${serviceName}-rsync-net-backup" = {
    onFailure = [ "ping-healthchecks@${serviceName}-rsync-net-backup:failure.service" ];
    onSuccess = [ "ping-healthchecks@${serviceName}-rsync-net-backup:success.service" ];
    wants = [ "ping-healthchecks@${serviceName}-rsync-net-backup:start.service" ];

    serviceConfig.LoadCredential = [ "rsync-net-ssh-key:${config.age.secrets.rsync-net-ssh.path}" ];
  };
}
