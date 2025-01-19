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
          flakeModuleLib = import ./lib { inherit self; };
        in
        # Attrset of package name (as visible to the consumer) and the enum type of package
        {
          vim-minimal = "min";
          vim = "std";
          vim-with-langs = "max";
        }
        |> lib.mapAttrs (
          _: it:
          flakeModuleLib.mkPackage {
            pkgType = it;
            inherit pkgs lib;
          }
        )
      );
    };

  flake =
    # For some reason, passing mkModule through lib causes moduleType to become
    # an attrset that is extremely weird. I think it's flake.parts fault
    # let
    #   # Both modules are very similar, so just build them using a "mode" flag below
    #   # inherit (import ./lib { inherit self; }) mkModule';
    # in
    {
      nixosModules.vim = import ./lib/mk-module.nix {
        inherit self;
        moduleType = "nixOS";
      };
      homeManagerModules.vim = import ./lib/mk-module.nix {
        # import ./lib/mk-module.nix {
        moduleType = "homeManager";
        inherit self;
      };
    };
}
