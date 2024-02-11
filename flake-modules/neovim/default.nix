/* Flake-module entry point for neovim configuration.

   It provides outputs for:

   - base neovim package with some plugins
   - neovim package with language servers
   - nixOS module for installing neovim
   - home-manager module for installing neovim
*/
{ withSystem, self }:
{

  perSystem =
    { system, ... }:
    {
      packages = withSystem system (
        { pkgs, ... }:
        let
          inherit (pkgs) lib;
        in
        rec {
          vimWithLangs = import ./mkPackage.nix {
            modConfig = {
              withLangServers = true;
            };
            inherit lib pkgs;
            moduleToEval = self.homeManagerModules.vim;
          };
          vim = import ./mkPackage.nix {
            modConfig = {
              withLangServers = false;
            };
            inherit lib pkgs;
            moduleToEval = self.homeManagerModules.vim;
          };
          nvim = vim;
          nvimWithLangs = vimWithLangs;
          neovim = vim;
          neovimWithLangs = vimWithLangs;
        }
      );
    };

  flake =
    let
      # Both modules are very similar, so just build them using a "mode" flag below
      moduleBuilder = import ./modules self;
    in
    {
      nixosModules.vim = moduleBuilder "nixOS";
      homeManagerModules.vim = moduleBuilder "homeManager";
    };
}
