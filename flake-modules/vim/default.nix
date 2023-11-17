# Flake module that exposes my custom neovim package and a module to configure it
{ withSystem, self }:
{
  perSystem = { system, ... }: {
    packages = withSystem system ({ inputs', ... }:
      let
        pkgBuilder = import ./packages;
        commonArgs = {
          pkgs = inputs'.nixpkgs-unstable.legacyPackages; # Vim is tracking the unstable packages
          inherit (self) inputs;
        };
        vim = pkgBuilder commonArgs;
        vimWithLangs = pkgBuilder (commonArgs // { enableLangServers = true; });
      in
      (rec {
        inherit vim vimWithLangs;
        nvim = vim;
        nvimWithLangs = vimWithLangs;
        neovim = vim;
        neovimWithLangs = vimWithLangs;
      }));
  };
  flake =
    let
      # Both modules are very similar, so just build them using a "mode" flag below
      moduleBuilder = import ./modules;
    in
    {
      nixosModules.vim = moduleBuilder { localFlake = self; mode = "nixOS"; };
      homeManagerModules.vim = moduleBuilder { localFlake = self; mode = "homeManager"; };
    };
}
