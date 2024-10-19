# NixOS module that configures gitea
_: {
  imports = [
    ./gitea.nix
    ./ssl.nix
    ./bkp.nix
    ./monitoring.nix
    ./network.nix
  ];
}
