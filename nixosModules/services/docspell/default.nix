{ docspell-flake, ... }:
{
  imports = [
    docspell-flake.nixosModules.default
    ./docspell.nix
    ./ssl.nix
  ];
}
