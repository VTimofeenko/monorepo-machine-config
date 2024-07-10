# Configure reverse DNS lookups on unbound side
{ config, lib, ... }:
let
  inherit (config.my-data) networks;
  inherit (lib.localLib) pluck;
  inherit (lib)
    filterAttrs
    pipe
    splitString
    reverseList
    concatStringsSep
    elemAt
    last
    unique
    ;

  subnetsInArpa = pipe networks [
    (filterAttrs (n: _: builtins.elem n networks.allNetworks)) # filter only actual networks, get an attrset back
    (pluck "subnet") # -> list of "subnet" values
    (map (splitString "."))
    (map reverseList)
    (map (concatStringsSep "."))
  ];

  localZones = pipe subnetsInArpa [
    (map (splitString "."))
    # Unbound has certain zones that need to be explicitly configured as nodefault
    # The set of the reverse zones is different compared to my networks
    (map (
      x:
      if (elemAt x 1) == "168" && (elemAt x 2) == "192" then
        "168.192"
      else if (last x) == "10" then
        "10"
      else if (elemAt x 1) == "16" && (elemAt x 2) == "172" then
        "16.172"
      else
        builtins.abort "Unexpected format ${toString x}"
    ))
    (map (x: "${x}.in-addr.arpa."))
    unique
  ];
  forwardZones = map (x: "${x}.in-addr.arpa.") subnetsInArpa;
in

{
  services.unbound.settings = {
    server.local-zone = map (x: "${x} nodefault") localZones;
    server.domain-insecure = localZones;
    forward-zone = map (name: {
      inherit name;
      forward-addr = "127.0.0.1@${toString config.services.nsd.port}";
    }) forwardZones;
  };
}
