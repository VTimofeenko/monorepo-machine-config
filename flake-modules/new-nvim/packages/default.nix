neovimPkg:
{ pkgs, inputs }:
let
  standardPlugins = import ./plugins.nix { inherit pkgs inputs; };

  initLua =
    lib.concatMapStringsSep "\n" builtins.readFile [
      ./init/base.lua
      ./init/file-specific.lua
      ./init/kitty-scrollback-override.lua
    ]
    + ''
      vim.opt.clipboard = 'unnamed${if pkgs.stdenv.isLinux then "plus" else ""}'
    '';

  inherit (pkgs) lib;
in
{
  baseNvim = import ./packageBuilder.nix {
    inherit neovimPkg pkgs initLua;
    inherit (standardPlugins) plugins;
  };
  nvimWithLangs = import ./packageBuilder.nix {
    inherit neovimPkg pkgs initLua;
    inherit (standardPlugins) plugins;
  };
}
