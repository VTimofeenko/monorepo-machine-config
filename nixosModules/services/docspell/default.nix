{ docspell-flake, ... }:
{
  imports = [
    docspell-flake.nixosModules.default
    ./docspell.nix
    ./ssl.nix
    # TODO: backups with minio dump using dsc
  ];
}
