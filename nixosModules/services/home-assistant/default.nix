_: {
  # TODO: rework into the more standard imports = [ service.nix ... ] way
  imports = [
    ./ha.nix
    ./zwave.nix
    ./ssl.nix
    ./outlet-rebooter.nix
  ];
}
