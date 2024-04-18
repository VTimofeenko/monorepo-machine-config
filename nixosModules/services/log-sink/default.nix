/**
  Module that ingests the logs from log sources and pushes the logs to storage.
*/
_: {
  imports = [
    ./service.nix
    ./firewall.nix
    # ./ssl.nix # no ssl termination
    # ./bkp.nix # stateless => no bkp
  ];
}
