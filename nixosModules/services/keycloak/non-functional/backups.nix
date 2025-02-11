/**
  Combines the standard backup service with an override that dumps the database
  into runtime directory.

  According to `man systemd.exec`:

  In case of `RuntimeDirectory=` the innermost subdirectories are removed when the unit is stopped.

  So the dump will not persist past service invocation.
*/
{
  paths,
  schedule,
  serviceName,
  ...
}:
{ lib, ... }:
{
  imports = [
    (lib.localLib.mkBkp { inherit paths schedule serviceName; })
  ];

  # Overrides
  services.restic.backups = {
    "${serviceName}-localbackup" = {
      # This is a bit brittle as it hardcodes paths
      backupPrepareCommand = ''/run/wrappers/bin/sudo -u postgres '/run/current-system/sw/bin/pg_dumpall' > "$RUNTIME_DIRECTORY/pg_dumpall.sql"'';

      # Alternative -- `dynamicFilesFrom` NixOS option with ls? Might want to
      # try it out if this command breaks.
      paths = lib.mkForce [ "/run/restic-backups-keycloak-localbackup/pg_dumpall.sql" ];
    };
  };
}
