{ lib, pkgs, ... }:
# TODO:
# 0. Move password to secrets
# 1. Connect to remote IP
# 2. Configure actions explicitly (try on helium)
let
  srvConfig = lib.homelab.getServiceConfig "nut-client";
in
{
  power.ups = {
    users.upsmon = {
      passwordFile = toString (pkgs.writeText "password" srvConfig.password);
      upsmon = "master";
    };
  };
}
