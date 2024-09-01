# NixOS module that configures prometheus
_: {
  imports = [
    ./service.nix
    ./firewall.nix
    ./ssl.nix
    # ./bkp.nix
  ];
}
