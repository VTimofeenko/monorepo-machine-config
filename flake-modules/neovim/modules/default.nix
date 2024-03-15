# Produces NixOS or Home Manager module with the custom neovim
localFlake: # Reference to the flake
mode: # "homeManager" or "nixOS". Since the code is essentially the same, the difference is just a matter of paths

{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkPackageOption
    mkOption
    ;

  pkgs-unstable = localFlake.inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};

  cfg = config.programs.myNeovim;

  pluginsType =
    with lib.types;
    listOf attrsOf (
      submodule {
        options = {
          pkg = lib.mkOption { type = package; };
          config = lib.mkOption {
            type = str;
            description = lib.mdDoc "Plugin-related config snippet.";
          };
        };
      }
    );

  # Decide where to add the packages
  outer = if mode == "homeManager" then "home" else "environment";
  inner = if mode == "homeManager" then "packages" else "systemPackages";
in
{
  options.programs.myNeovim = {
    enable = mkEnableOption "My neovim with plugins";
    package = mkOption {
      type = lib.types.package;
      internal = true;
      readOnly = true;
    };
    basePackage = mkPackageOption localFlake.inputs.nvim-nightly.packages.${pkgs.system} "default" { };
    withLangServers = mkEnableOption "Enable language server plugins";

    plugins = mkOption {
      type = pluginsType;
      internal = true;
      readOnly = true;
      description = lib.mdDoc "Base included plugins";
    };
    extraPlugins = mkOption {
      # type = pluginsType; # TODO: debug this
      description = lib.mdDoc "Additional plugins";
      default = [ ];
    };

    initLua = mkOption {
      type = lib.types.str;
      internal = true;
      readOnly = true;
      description = lib.mdDoc "Base init.lua";
      default = import ./initLua.nix {
        inherit pkgs lib;
        colortheme = localFlake.data.my-colortheme; # Use the default values from my colorscheme
      };
    };
    extraInitLua = mkOption {
      type = lib.types.str;
      description = lib.mdDoc "Additional init.lua";
      default = "";
    };
  };

  config =
    let
      pkgBuilder = import ./packageBuilder.nix {
        neovimPkg = cfg.basePackage;
        inherit pkgs;
        inherit (cfg) initLua extraInitLua;
        inherit
          (import ./plugins.nix {
            pkgs = pkgs-unstable;
            inherit (localFlake) inputs;
            inherit (cfg) withLangServers extraPlugins;
          })
          plugins
          ;
        additionalPkgs = # TODO: separate this out
          builtins.attrValues {
            inherit (pkgs)
              fd # Quick find replacement
              ripgrep # Quick grep replacement
              ;
          }
          # Language-dependant packages
          ++ builtins.attrValues (
            if cfg.withLangServers then
              {
                inherit (pkgs-unstable)
                  nil # Nix lang server
                  rust-analyzer # Rust lang server
                  nls # Nickel language server
                  shellcheck # For shell files
                  lua-language-server # For lua
                  glow # for markdown previews
                  stylua # for lua static checks
                  nixfmt-rfc-style
                  ;
                # inherit (pkgs-unstable)
                inherit (pkgs.nodePackages)
                  bash-language-server # Bash language server
                  ;
              }
            else
              { }
          );
      };

      finalPackage = if cfg.withLangServers then pkgBuilder else pkgs.cowsay;
    in
    mkIf cfg.enable {
      ${outer}.${inner} = [ finalPackage ];
      programs.myNeovim.package = finalPackage;
    };
}
