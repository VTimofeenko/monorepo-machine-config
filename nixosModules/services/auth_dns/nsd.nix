{ lib, ... }:
let
  thisSrvConfig = lib.homelab.getServiceConfig "auth_dns";
  srvLib = import ./lib.nix;
in
{
  imports = [ ./service ];
  services.nsd = {
    enable = true;
    inherit (thisSrvConfig) port;
    interfaces = [ "127.0.0.1" ];
    zones = lib.mapAttrs (domain: recordsData: {
      data = srvLib.mkZoneData { inherit domain recordsData lib; };
    }) thisSrvConfig.zoneRecords;
  };
}
