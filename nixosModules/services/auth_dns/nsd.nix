{ lib
, config
, ...
}:
let
  inherit (config) my-data;
  thisSrvConfig = my-data.lib.getServiceConfig "auth_dns_1"; # FIXME: flaky _1 addressing
  srvLib = import ./lib.nix;
  mkZoneData' = networkName: srvLib.mkZoneData { inherit my-data lib networkName; };
in
{
  services.nsd = {
    enable = true;
    inherit (thisSrvConfig) port;
    interfaces = [ "127.0.0.1" ];
    zones = lib.attrsets.mapAttrs'
      (networkName: networkData: lib.attrsets.nameValuePair
        networkData.domain
        { data = mkZoneData' networkName; })
      my-data.networks.allNetworks;
  };
}
