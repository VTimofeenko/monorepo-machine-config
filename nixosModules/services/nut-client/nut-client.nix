{ lib, config, ... }:
let
  inherit (lib.homelab) getServiceConfig getServiceSecret getServiceIP;
  serverServiceName = "nut-server";
  serverCfg = getServiceConfig serverServiceName;
in
{
  age.secrets.nut-password.file = getServiceSecret "nut-client" "password";

  power.ups = {
    enable = true;
    mode = "netclient"; # This will be overridden by mkForce "netserver" on the actual server

    upsmon.settings = {
      POWERDOWNFLAG = "/var/state/ups/killpower";
      NOTIFYFLAG = [
        [
          "ONLINE"
          "SYSLOG+WALL"
        ]
        [
          "ONBATT"
          "SYSLOG+WALL"
        ]
        [
          "LOWBATT"
          "SYSLOG+WALL"
        ]
        [
          "FSD"
          "SYSLOG+WALL"
        ]
        [
          "COMMOK"
          "EXEC"
        ]
        [
          "COMMBAD"
          "EXEC"
        ]
        [
          "SHUTDOWN"
          "SYSLOG+WALL"
        ]
        [
          "REPLBATT"
          "SYSLOG+WALL"
        ]
        [
          "NOCOMM"
          "SYSLOG+WALL+EXEC"
        ]
        [
          "NOPARENT"
          "SYSLOG+WALL"
        ]
      ];
    };
    upsmon.monitor.${serverCfg.UPS.model} = {
      user = if config.power.ups.mode == "netserver" then "primary-client" else "secondary-client";
      system = "${serverCfg.UPS.model}@${getServiceIP serverServiceName}:3493";
      passwordFile = config.age.secrets.nut-password.path;
      type =
        let
          match = {
            netserver = "primary";
            netclient = "secondary";
          };
        in
        match.${config.power.ups.mode};
    };

  };
  imports = [ ./upssched.nix ];
}
