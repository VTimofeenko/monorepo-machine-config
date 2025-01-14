/*
  Flake-module entry point for neovim configuration.

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
          flakeModuleLib = import ./lib { inherit pkgs lib self; };
        in
        # Attrset of package name (as visible to the consumer) and the enum type of package
        {
          vim-minimal = "min";
          vim = "std";
          vim-with-langs = "max";
        }
        |> lib.mapAttrs (_: v: flakeModuleLib.mkPackage v)
      );
    };

  flake =
    let
      # Both modules are very similar, so just build them using a "mode" flag below
      moduleBuilder = import ./lib/mk-module.nix;
    in
    {
      nixosModules.vim = moduleBuilder {
        inherit self;
        mode = "nixOS";
      };
      homeManagerModules.vim = moduleBuilder {
        inherit self;
        mode = "homeManager";
      };
    };
}
