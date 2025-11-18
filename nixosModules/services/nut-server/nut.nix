# NixOS module that configures the UPS monitoring daemon
{ config, lib, ... }:
let
  srvName = "nut-server";
  srvCfg = lib.homelab.getServiceConfig srvName;
in
{
  age.secrets.nut-password.file = lib.homelab.getServiceSecret "nut-client" "password";
  power.ups = {
    enable = true;
    mode = lib.mkForce "netserver";
    ups.${srvCfg.UPS.model} = with srvCfg.UPS; {
      driver = "usbhid-ups";
      port = "auto";
      directives = [
        "vendorid = ${vendorId}" # Result from `lsusb`
        "productid = ${productId}" # Result from `lsusb`
      ];
      inherit description;
    };

    users = {
      # Upsmon makes the following distinction between users:
      # * primary = "UPS is connected to this machine, shut it down last"
      # * secondary = "UPS" is not connected to this machine, start shutdown here first
      primary-client = {
        passwordFile = config.age.secrets.nut-password.path;
        upsmon = "primary";
      };
      secondary-client = {
        passwordFile = config.age.secrets.nut-password.path;
        upsmon = "secondary";
      };
    };
  };
}
