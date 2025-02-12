_: {
  imports = [
    ./nextcloud.nix
    ./ssl.nix
    (import ./manifest.nix).backups.impl
  ];
}
