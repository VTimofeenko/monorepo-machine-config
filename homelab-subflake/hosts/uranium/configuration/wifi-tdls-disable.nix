/**
  On the 7.X kernel, TDLS peer setup fails with:

  ```
  wpa_supplicant[...]: nl80211: kernel reports: key addition failed
  wpa_supplicant[...]: TDLS: Failed to set TPK to the driver
  ```

  which then kills wifi. TDLS can't be disabled from the wpa_supplicant
  config file, so it's disabled at runtime via wpa_cli once wpa_supplicant
  is up.

  wpa_supplicant.service is Type=simple, so `after` only orders against the
  exec, not the control socket being ready; retry until wpa_cli connects.
*/
{ pkgs, lib, ... }:
let
  disableTdls = pkgs.writeShellScript "wpa-tdls-disable" ''
    for _ in $(seq 50); do
      ${lib.getExe' pkgs.wpa_supplicant "wpa_cli"} -p /run/wpa_supplicant/control -i phy-lan set tdls_disabled 1 && exit 0
      sleep 0.2
    done
    echo "wpa_supplicant control socket for phy-lan not ready after 10s" >&2
    exit 1
  '';
in
{
  systemd.services.wpa-tdls-disable = {
    description = "Disable TDLS on phy-lan (workaround for 7.X kernel TDLS key install failure)";
    after = [ "wpa_supplicant.service" ];
    partOf = [ "wpa_supplicant.service" ];
    wantedBy = [ "wpa_supplicant.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = disableTdls;
    };
  };
}
