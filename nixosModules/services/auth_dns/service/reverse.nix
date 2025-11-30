{ config, lib, ... }:
let
  inherit (config.my-data) networks;
  inherit (lib.localLib) splitReverseJoin;
  inherit (lib)
    filterAttrs
    pipe
    concatStringsSep
    mapAttrs
    nameValuePair
    attrValues
    removePrefix
    mapAttrs'
    ;

  subnetsInArpa = pipe networks [
    (filterAttrs (n: _: builtins.elem n networks.allNetworks)) # filter only actual networks, get an attrset back
    (mapAttrs' (
      _: value:
      nameValuePair
        (pipe value.subnet [
          splitReverseJoin
          (x: "${x}.in-addr.arpa") # -> produces zone name
        ])
        (
          pipe value.hostsInNetwork [
            attrValues
            (map (x: {
              inherit (x) fqdn;
              recordData = pipe x.ipAddress [
                (removePrefix "${value.subnet}.")
                splitReverseJoin
              ];
            }))
            (map (x: "${x.recordData} IN PTR ${x.fqdn}."))
          ]
        )
    )) # Construct an attrset of zones and records
  ];
in
{
  services.nsd.zones =
    (mapAttrs (
      name: value: {
        data = ''
          $ORIGIN ${name}.
          $TTL 86400
          @ IN SOA ns1.home.arpa. admin.home.arpa. (
              2024071012 ; Serial
              3600       ; Refresh
              900        ; Retry
              1209600    ; Expire
              86400 )    ; Minimum TTL

          @ IN NS ns1.home.arpa.
          @ IN NS ns2.home.arpa.

          ${concatStringsSep "\n" value}

        '';
      }
    ))
      subnetsInArpa;
}
