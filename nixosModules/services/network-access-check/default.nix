{ pkgs, lib, ... }:
let
  inherit (lib.homelab) getServiceConfig getServiceFqdn;
  srvName = "network-access-check";
  UUID = (getServiceConfig srvName).HCGUID;
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
        in
        # bash
        ''
          ${curl} \
                --fail `#fail fast on server errors` \
                --show-error --silent `#show error <=> it fails` \
                --max-time 10 \
                --retry 3 \
                "https://${getServiceFqdn "healthchecks"}/ping/${UUID}"
        '';
    };
  };
}
