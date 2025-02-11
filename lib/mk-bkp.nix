/**
  Function that produces a module implementing backups.
*/
{
  paths,
  exclude ? [ ],
  schedule,
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
      inherit paths exclude;
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
