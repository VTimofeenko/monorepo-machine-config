{
  imports = [
    ./ha.nix
    ./zwave.nix
    ./ssl.nix
    ./outlet-rebooter.nix
    ./monitoring.nix
    (import ./manifest.nix).backups.impl
  ];
}
