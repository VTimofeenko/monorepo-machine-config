neovimPkg:
{ pkgs, inputs }:
let
  standardPlugins = import ./plugins.nix { inherit pkgs inputs; };

  initLua = lib.concatMapStringsSep "\n" builtins.readFile [
    ./init/base.lua
    ./init/file-specific.lua
    ./init/kitty-scrollback-override.lua
  ];

  inherit (pkgs) lib;
in
import ./packageBuilder.nix {
  inherit neovimPkg pkgs initLua;
  inherit (standardPlugins) plugins;
}
