/**
  Creates a systemd service template
*/
{ lib, pkgs, ... }:
{
  systemd.services."ping-healthchecks@" = {
    serviceConfig.ExecStart =
      let
        ping-hc = pkgs.writeShellApplication {
          name = "ping-hc";
          runtimeInputs = [ pkgs.curl ];
          text =
            let
              baseUrl = "https://${lib.homelab.getServiceFqdn "healthchecks"}/ping/${(lib.homelab.getServiceConfig "healthchecks").pingKey}";
            in
            # bash
            ''
              # If I ever want to debug this:
              # env
              # set -x

              # Source: https://passbe.com/2022/healthchecks-io-systemd-checks/
              # Parse the template variable into actions
              IFS=:
              read -r SLUG ACTION <<< "$1"

              # Remove "@localhost" from the SLUG
              SLUG="''${SLUG%%@localhost}"

              if [ "$ACTION" = "start" ]; then
                LOGS=""
                EXIT_CODE="start"
                # Auto provision the check by slug
                curl \
                  --fail `#fail fast on server errors` \
                  --show-error --silent `#show error <=> it fails` \
                  --max-time 10 \
                  --retry 3 \
                  "${baseUrl}/$SLUG/$EXIT_CODE?create=1"
              elif [ "$ACTION" = "success" ]; then
                # Signal success without collecting logs
                curl \
                  --fail `#fail fast on server errors` \
                  --show-error --silent `#show error <=> it fails` \
                  --max-time 10 \
                  --retry 3 \
                  "${baseUrl}/$SLUG"
              else
                # Signal failure and collect logs

                # Get logs of last invocation
                # Source:
                # https://serverfault.com/questions/768901/is-there-a-way-to-make-journalctl-show-logs-from-the-last-time-foo-service-ran
                # Slight tweak -- needs InactiveExitTimestamp ?
                LAST_TIMESTAMP=$(systemctl show --property InactiveExitTimestamp --value "$MONITOR_UNIT")
                LOGS=$(journalctl --no-pager -u "$MONITOR_UNIT" --since "$LAST_TIMESTAMP")

                # This will be 1 in case of error
                # Healthchecks supports "fail" or 1 for this:
                # https://healthchecks.io/docs/signaling_failures/
                EXIT_CODE=''${MONITOR_EXIT_STATUS:-"fail"}
                curl \
                  --fail `#fail fast on server errors` \
                  --show-error --silent `#show error <=> it fails` \
                  --max-time 10 \
                  --retry 3 \
                  --data-raw "$LOGS" \
                  "${baseUrl}/$SLUG/$EXIT_CODE"
              fi
            '';
        };
      in
      "${lib.getExe ping-hc} %i";
  };
}
