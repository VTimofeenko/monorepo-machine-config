# Configure reverse DNS lookups on unbound side
{ lib, ... }:
let
  # Standardize on port 5454 as per migration notes
  nsdPort = 5454;
  inherit (lib.localLib) splitReverseJoin;
  inherit (lib)
    pipe
    splitString
    elemAt
    last
    unique
    ;

  # List of networks to configure reverse DNS for
  networksToReverse = [
    "lan"
    "backbone"
    "backbone-inner"
    "mgmt"
    "db"
    "client"
  ];

  subnetsInArpa = pipe networksToReverse [
    (map (networkName: (lib.homelab.getNetwork networkName).subnet))
    (map splitReverseJoin)
  ];

  localZones = pipe subnetsInArpa [
    (map (splitString "."))
    # Unbound has certain zones that need to be explicitly configured as `nodefault`
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
      # Use standardized port 5454
      forward-addr = "127.0.0.1@${toString nsdPort}";
    }) forwardZones;
  };
}
