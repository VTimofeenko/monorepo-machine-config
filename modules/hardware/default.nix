# [[file:../../new_project.org::*Hardware][Hardware:1]]
{ ... }:
{
  imports = [
    ./disks.nix # (ref:disks-import)
    ./scanner.nix # (ref:scanner-import)
    ./printer.nix # (ref:printer-import)
    ./keyboard.nix # (ref:keyboard-import)
  ];
}
# Hardware:1 ends here
