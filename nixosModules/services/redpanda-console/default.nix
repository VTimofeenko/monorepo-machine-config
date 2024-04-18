/**
  Module that provides a console for redpanda.
*/
_: {
  imports = [
    ./service.nix
    # ./firewall.nix # No special incoming connections
    ./ssl.nix
    # ./bkp.nix # stateless => no bkp
  ];
}
