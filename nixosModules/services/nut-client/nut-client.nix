{ lib, config, ... }:
let
  # srvConfig = lib.homelab.getServiceConfig "nut-client";
  inherit (lib.homelab) getServiceConfig getServiceSecret getServiceIP;
  serverServiceName = "nut-server";
  serverCfg = getServiceConfig serverServiceName;
in
{
  age.secrets.nut-password.file = getServiceSecret "nut-client" "password";

  power.ups = {
    mode = "netclient"; # This will be overridden by mkForce "netserver" on the actual server

    upsmon.monitor.${serverCfg.UPS.model} = {
      user = if config.power.ups.mode == "netserver" then "primary-client" else "secondary-client";
      system = "${serverCfg.UPS.model}@${getServiceIP serverServiceName}:3493";
      passwordFile = config.age.secrets.nut-password.path;
    };

  };
}
