{ pkgs, lib, ... }:
let
  inherit (lib.homelab) getServiceConfig getServiceFqdn;
  srvName = "network-access-check";
in
{
  systemd = {
    timers."ping-${srvName}" = {
      timerConfig = {
        OnCalendar = "*:0/5";
        Persistent = true;
      };
      wantedBy = [ "multi-user.target" ];
      # Maybe after network?
    };

    services."ping-${srvName}" = {
      description = "Reboot the outlet just in case";
      script =
        let
          curl = lib.getExe' pkgs.curl "curl";
          baseUrl = "https://${getServiceFqdn "healthchecks"}/ping/${(getServiceConfig "healthchecks").pingKey}";
        in
        # bash
        ''
          ${curl} \
                --fail `#fail fast on server errors` \
                --show-error --silent `#show error <=> it fails` \
                --max-time 10 \
                --retry 3 \
                "${baseUrl}/${srvName}?create=1"
        '';
    };
  };
}
