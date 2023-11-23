/*
  This module builds the neovim shell application
*/

{ pkgs # nixpkgs packages
, lib # nixpkgs lib
, plugins # List of plugins to turn into packages and config
, baseInit # Base init.lua file
, additionalPkgs # Additional packages (language servers, etc.) to bring into vim PATH
, ...
}:
let
  # TODO: Proper types for the plugins?

  # writeTextFile writes and returns a _file_. writeText returns text
  initLuaFile = pkgs.writeTextFile
    {
      name = "init.lua";
      text = baseInit
        +
        lib.concatMapStringsSep
          "\n"
          (plugin: (plugin.config or "")) # TODO: maybe try to auto-load the config file using lib.sources.pathIsRegularFile to check if a plugin-dedicated config exists
          plugins;
    };
  nvimConfig = pkgs.neovimUtils.makeNeovimConfig {
    plugins = builtins.map
      # If just a package was passed -- just throw it in as is. Otherwise -- need only the package
      (a: if lib.attrsets.isDerivation a then a else a.pkg)
      plugins;
    withPython3 = true;
    withRuby = true;
  };
  wrapperArgs = nvimConfig.wrapperArgs ++ [
    "--prefix"
    "PATH"
    ":"
    (lib.makeBinPath additionalPkgs)
  ];
  wrappedNvim = pkgs.wrapNeovimUnstable
    pkgs.neovim-unwrapped
    (nvimConfig // { inherit wrapperArgs; });
in
pkgs.writeShellApplication {
  name = "nvim";
  runtimeInputs = [ wrappedNvim ];
  text = "nvim -u ${initLuaFile} \"$@\"";
}
