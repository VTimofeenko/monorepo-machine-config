/**
  On the 7.X kernel, TDLS peer setup fails with:

  ```
  wpa_supplicant[...]: nl80211: kernel reports: key addition failed
  wpa_supplicant[...]: TDLS: Failed to set TPK to the driver
  ```

  which then kills wifi. TDLS can't be disabled from the wpa_supplicant
  config file, so it's disabled at runtime via wpa_cli once wpa_supplicant
  is up.
*/
{ pkgs, lib, ... }:
{
  systemd.services.wpa-tdls-disable = {
    description = "Disable TDLS on wifi-lan (workaround for 7.X kernel TDLS key install failure)";
    after = [ "wpa_supplicant.service" ];
    partOf = [ "wpa_supplicant.service" ];
    wantedBy = [ "wpa_supplicant.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${lib.getExe' pkgs.wpa_supplicant "wpa_cli"} -p /run/wpa_supplicant/control -i wifi-lan set tdls_disabled 1";
    };
  };
}
