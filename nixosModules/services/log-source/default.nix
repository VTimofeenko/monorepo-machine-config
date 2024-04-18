/**
  Module that emits the logs from local sources into the sink
*/
_: {
  imports = [
    ./service.nix
    # ./firewall.nix # No incoming connections
    # ./ssl.nix # no ssl termination
    # ./bkp.nix # stateless => no bkp
  ];
}
