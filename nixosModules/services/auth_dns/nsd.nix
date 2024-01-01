{ lib
, config
, ...
}:
let
  inherit (config) my-data;
  thisSrvConfig = my-data.lib.getServiceConfig "auth_dns_1"; # FIXME: flaky _1 addressing
  srvLib = import ./lib.nix;
in
{
  services.nsd = {
    enable = true;
    inherit (thisSrvConfig) port;
    interfaces = [ "127.0.0.1" ];
    zones =
      lib.mapAttrs
        (domain: recordsData: { data = srvLib.mkZoneData { inherit domain recordsData lib; }; })
        thisSrvConfig.zoneRecords
    ;
  };
}
