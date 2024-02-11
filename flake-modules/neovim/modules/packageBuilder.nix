# Builds the neovim package with all packages and plugins
{
  neovimPkg,
  pkgs,
  plugins ? [ ],
  initLua,
  extraInitLua ? "",
  additionalPkgs ? [ ],
}:
let
  inherit (pkgs) lib;

  initLuaFile = pkgs.writeTextFile {
    name = "init.lua";
    text = lib.concatStringsSep "\n" (
      lib.flatten [
        initLua
        (map (plugin: (plugin.config or "")) plugins)
        extraInitLua
      ]
    );
  };

  nvimConfig = pkgs.neovimUtils.makeNeovimConfig {
    # If just a package was passed -- just throw it in as is. Otherwise -- need only the package
    plugins = builtins.map (a: if lib.attrsets.isDerivation a then a else a.pkg) plugins;
    withPython3 = true;
    withRuby = true;
  };

  wrapperArgs = nvimConfig.wrapperArgs ++ [
    "--prefix"
    "PATH"
    ":"
    (lib.makeBinPath additionalPkgs)
  ];

  wrappedNvim = pkgs.wrapNeovimUnstable neovimPkg (nvimConfig // { inherit wrapperArgs; });
in
pkgs.symlinkJoin {
  name = "nvim";
  paths = [ wrappedNvim ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/nvim \
      --add-flags "-u ${initLuaFile}" `# prepend my init.lua file`
  '';
}
