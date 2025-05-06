/*
  Flake-module entry point for neovim configuration.

  It provides outputs for:

  - Base neovim package with some plugins
  - neovim package with language servers
  - NixOS module for installing neovim
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
          vim-max = "max";
        }
        |> lib.mapAttrs (
          _: it:
          flakeModuleLib.mkPackage {
            pkgType = it;
            inherit pkgs lib;
          }
        )
      );

      # This bit adds checks dynamically.
      # By placing a `.nix` file in the `./checks/` directory, it will be:
      # 1. Automatically added to `flake.checks`
      # 2. Be prefixed with `flake-module-neovim-`
      checks = withSystem system (
        { pkgs, ... }:
        let
          inherit (pkgs) lib;
        in
        ./checks
        |> pkgs.lib.fileset.toList
        |> map (
          it:
          let
            fileName = it |> builtins.toString |> builtins.baseNameOf |> (lib.replaceStrings [ ".nix" ] [ "" ]);
          in
          {
            "flake-module-neovim-${fileName}" = import it { inherit pkgs self; };
          }
        )
        |> pkgs.lib.mergeAttrsList
      );
    };

  flake =
    # For some reason, passing `mkModule` through lib causes `moduleType` to become
    # an attrset that is extremely weird. I think it's flake.parts fault
    # ```
    # let
    #   # Both modules are very similar, so just build them using a "mode" flag below
    #   # inherit (import ./lib { inherit self; }) mkModule';
    # in
    # ```
    {
      nixosModules.vim = import ./lib/mk-module.nix {
        inherit self;
        moduleType = "nixOS";
      };
      homeManagerModules.vim = import ./lib/mk-module.nix {
        moduleType = "homeManager";
        inherit self;
      };
    };
}
