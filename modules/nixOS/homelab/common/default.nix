/* Modules that are common across all machines in the homelab */
_:
{
  imports = [
    ./dump.nix
    ./firewall.nix
    ./nix.nix
    ./packages.nix
    ./shell.nix
    ./sshd.nix
    ./time.nix
  ];
}
