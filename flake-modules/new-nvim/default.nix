# Flake module that exposes my custom neovim package and a module to configure it
{ withSystem, self }:
{
  perSystem =
    { system, ... }:
    {
      packages = withSystem system (
        { inputs', ... }:
        let
          newVim = import ./packages inputs'.nvim-nightly.packages.default {
            inherit (self) inputs;
            pkgs = inputs'.nixpkgs-unstable.legacyPackages;
          };
        in
        {
          inherit newVim;
        }
      );
    };
}
