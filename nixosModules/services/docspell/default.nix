{ docspell-flake, lib, ... }:
{
  imports = [
    docspell-flake.nixosModules.default
    (import ./manifest.nix).default
  ] |> lib.flatten;
}
