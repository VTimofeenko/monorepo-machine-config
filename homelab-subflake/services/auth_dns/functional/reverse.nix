{ lib, ... }:
let
  inherit (lib.localLib) splitReverseJoin;
  inherit (lib)
    pipe
    concatStringsSep
    mapAttrs
    nameValuePair
    attrValues
    removePrefix
    ;

  srvLib = import ../srv-lib.nix;

  # Get nameserver IPs for zone SOA/NS records
  nameserverIPs = srvLib.getNameserverIPs { inherit lib; };

  # List of networks to generate reverse zones for
  networksToReverse = [
    "lan"
    "backbone"
    "backbone-inner"
    "mgmt"
    "db"
    "client"
  ];

  # Generate reverse zone records for all configured networks
  subnetsInArpa = pipe networksToReverse [
    (map (networkName: {
      network = lib.homelab.getNetwork networkName;
      inherit networkName;
    }))
    (map (
      { network, networkName }:
      nameValuePair
        (pipe network.subnet [
          splitReverseJoin
          (x: "${x}.in-addr.arpa") # -> produces zone name
        ])
        (
          pipe network.hostsInNetwork [
            attrValues
            (map (x: {
              inherit (x) fqdn;
              recordData = pipe x.ipAddress [
                (removePrefix "${network.subnet}.")
                splitReverseJoin
              ];
            }))
            (map (x: "${x.recordData} IN PTR ${x.fqdn}."))
          ]
        )
    ))
    builtins.listToAttrs
  ];
in
{
  # Generate full zone configuration using srvLib.mkZoneBase
  services.nsd.zones = mapAttrs (name: records: 
    let
      base = srvLib.mkZoneBase { 
        domain = name; 
        inherit nameserverIPs lib; 
        ttl = 86400; # 1 day TTL for reverse zones
      };
    in
    {
      data = base.data + "\n" + (concatStringsSep "\n" records) + "\n";
    }
  ) subnetsInArpa;
}
