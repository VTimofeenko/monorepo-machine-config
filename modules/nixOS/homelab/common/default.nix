# Modules that are common across all machines in the homelab
_: {
  imports = [
    ./dump.nix
    ./firewall.nix
    ./nix.nix
    ./disable_docs.nix
    ./packages.nix
    ./shell.nix
    ./sshd.nix
    ./time.nix
    ./resolved.nix
  ];
}
