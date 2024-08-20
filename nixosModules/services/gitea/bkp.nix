/*
  Backup implementation for gitea.

  For now only rotates on-device dumps.

  # TODO: move the script into flake-level packages
*/
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.services) gitea;
  inherit (lib.homelab) getServiceFqdn getServiceBackups;

  srvName = "gitea";
in
{
  services.gitea.dump = {
    enable = true;
    interval = "04:31"; # Daily, at 4AM
  };
  systemd = {

    tmpfiles.rules =
      assert lib.assertMsg gitea.dump.enable "This module needs gitea.dump.enable but it's disabled";
      [ "d ${gitea.dump.backupDir}/ 0750 ${gitea.user} ${gitea.group} 14d" ];

    services = {
      gitea-dump.unitConfig =
        let
          checkId = (getServiceBackups srvName).local.HCGUID;
        in
        {
          OnFailure = "ping-healthchecks@${checkId}:failure.service";
          OnSuccess = "ping-healthchecks@${checkId}:success.service";
          Wants = "ping-healthchecks@${checkId}:start.service";
        };

      "ping-healthchecks@" = {
        serviceConfig.ExecStart =
          let
            ping-hc = pkgs.writeShellApplication {
              name = "ping-hc";
              runtimeInputs = [ pkgs.curl ];
              text = ''
                # If I ever want to debug this:
                # env
                # set -x

                # Source: https://passbe.com/2022/healthchecks-io-systemd-checks/
                # Parse the template variable into actions
                IFS=:
                read -r UUID ACTION <<< "$1"

                # Remove "@localhost" from the UUID
                UUID="''${UUID%%@localhost}"

                if [ "$ACTION" = "start" ]; then
                  LOGS=""
                  EXIT_CODE="start"
                else
                  # Get logs of last invocation
                  # Source:
                  # https://serverfault.com/questions/768901/is-there-a-way-to-make-journalctl-show-logs-from-the-last-time-foo-service-ran
                  # Slight tweak -- needs InactiveExitTimestamp ?
                  LAST_TIMESTAMP=$(systemctl show --property InactiveExitTimestamp --value "$MONITOR_UNIT")
                  LOGS=$(journalctl --no-pager -u "$MONITOR_UNIT" --since "$LAST_TIMESTAMP")

                  # This will be 1 in case of error
                  # Healthchecks supports "fail" or 1 for this:
                  # https://healthchecks.srv.vtimofeenko.com/docs/signaling_failures/
                  EXIT_CODE=$MONITOR_EXIT_STATUS
                fi

                curl \
                  --fail `#fail fast on server errors` \
                  --show-error --silent `#show error <=> it fails` \
                  --max-time 10 \
                  --retry 3 \
                  --data-raw "$LOGS" \
                  "https://${getServiceFqdn "healthchecks"}/ping/$UUID/$EXIT_CODE"
              '';
            };
          in
          "${lib.getExe ping-hc} %i";
      };
    };
  };
}
