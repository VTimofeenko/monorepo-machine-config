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
      lib.attrsets.mergeAttrsList
        (
          map
            (args: {
              ${args.domain}.data = srvLib.mkZoneData { inherit my-data lib; inherit (args) domain networkName services; };
            })
            thisSrvConfig.zones
        )
      //
      thisSrvConfig.dbZone
    ;
  };
}
