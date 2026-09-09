/**
  Flake module for `vidir-img`: `vidir` (`moreutils`) with an image thumbnail
  preview for the file under the cursor, meant for bulk-renaming images.

  Lua code is in `../neovim/config/standard/vidir-img.nix`

  Manual `default.nix`, not `package.nix`: needs `self.packages.${system}.vim`
  (from the `neovim` module), which plain `pkgs.callPackage` (what
  `package.nix` auto-discovery uses) has no way to supply.

  Test with e.g. `nix run .#vidir-img -- <dir-with-images>`.

  `programs.vidir-img.enable` (NixOS + home-manager) installs the package
  -- see `mkModule` below.
*/
{
  withSystem,
  self,
  lib,
}:
let
  # `programs.vidir-img.enable` -> installs the package. Same
  # outer/inner indirection as `../neovim/lib/mk-module.nix`.
  mkModule =
    moduleType:
    let
      outer = if moduleType == "homeManager" then "home" else "environment";
      inner = if moduleType == "homeManager" then "packages" else "systemPackages";
    in
    { pkgs, lib, config, ... }:
    {
      options.programs.vidir-img.enable = lib.mkEnableOption "vidir-img (vidir with an image thumbnail preview)";
      config = lib.mkIf config.programs.vidir-img.enable {
        ${outer}.${inner} = [ self.packages.${pkgs.stdenv.hostPlatform.system}.vidir-img ];
      };
    };
in
{
  perSystem =
    { system, ... }:
    {
      packages = withSystem system (
        { pkgs, ... }:
        {
          vidir-img = pkgs.writeShellScriptBin "vidir-img" ''
            # Force uses standard `vim`
            export EDITOR="${lib.getExe' self.packages.${system}.vim "nvim"}"
            # `$VISUAL` also has to be set: vidir checks it *after* `$EDITOR`
            # and prefers it when present
            export VISUAL="$EDITOR"
            export VIDIR_IMAGE_PREVIEW=1
            exec ${lib.getExe' pkgs.moreutils "vidir"} --verbose "$@"
          '';
        }
      );
    };

  flake = {
    nixosModules.vidir-img = mkModule "nixOS";
    homeManagerModules.vidir-img = mkModule "homeManager";
  };
}
