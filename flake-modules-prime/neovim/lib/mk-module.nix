# Implementation of the function that produces a [NixOS|Home-manager] module
{ self, moduleType, ... }:
let
  # Decide which attribute path to set
  outer = if moduleType == "homeManager" then "home" else "environment";
  inner = if moduleType == "homeManager" then "packages" else "systemPackages";
in
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.programs.myNeovim;
  pluginsType =
    with lib.types;
    listOf (attrsOf (submodule {
      options = {
        pkg = lib.mkOption { type = package; };
        config = lib.mkOption {
          type = str;
          description = lib.mdDoc "Plugin-related config snippet.";
        };
      };
    }));
  inherit (lib)
    types
    mkEnableOption
    mkIf
    mkPackageOption
    mkOption
    ;

in
{
  options.programs.myNeovim = {
    enable = mkEnableOption "My neovim with plugins";

    type = mkOption {
      default = "min";
      type = types.enum [
        "min"
        "std"
        "max"
      ];
    };

    basePackage = mkPackageOption pkgs "neovim-unwrapped" { };

    extraPlugins = mkOption {
      type = pluginsType;
      description = lib.mdDoc "Additional plugins";
      default = [ ];
    };

    extraInitLua = mkOption {
      type = lib.types.str;
      description = lib.mdDoc "Additional init.lua";
      default = "";
    };

    # Used by the dynamic package generator later
    finalPackage = mkOption {
      type = lib.types.package;
      internal = true;
      readOnly = true;
    };

    # finalPackage
    # Take basePackage
    # Add plugins (depending on the type)
    # Add initlua from all the plugins
    # Append extraInitLua
    # Produce the package

  };
  config =
    let
      configFromType =
        ../config |> (it: import it { inherit pkgs lib self; }) |> builtins.getAttr cfg.type;

      extraPluginsNormalized = lib.flatten (map lib.attrValues cfg.extraPlugins);

      standardInitLua = (
        configFromType.initLua
        # Append from extraPlugins
        + "\n"
        + (lib.concatStringsSep "\n" (map (it: it.config) extraPluginsNormalized))
        # Append from extraInitLua
        + "\n"
        + cfg.extraInitLua
      );

      initLua =
        standardInitLua
        |> (
          it:
          pkgs.writeTextFile {
            name = "init.lua";
            text = it;
          }
        );

      # Plugins list for makeNeovimConfig
      # If lazy: all plugins are optional, except lazy.nvim
      # If standard: all plugins are eager

      plugins = configFromType.plugins ++ (map (it: it.pkg) extraPluginsNormalized);

      finalPackage =
        # Take basePackage
        cfg.basePackage
        # Add computed plugins
        |> (
          it:
          pkgs.wrapNeovimUnstable it {
            inherit plugins;
            withPython3 = true;
            withRuby = false;
            wrapperArgs = [
              "--prefix"
              "PATH"
              ":"
              (lib.makeBinPath configFromType.packages)
            ];
          }
        )
        # Produce the package
        |> (
          it:
          pkgs.symlinkJoin {
            name = "nvim";
            paths = [ it ];
            buildInputs = [ pkgs.makeWrapper ];
            postBuild = "wrapProgram $out/bin/nvim --add-flags '-u ${initLua}'";
          }
        );

    in
    mkIf cfg.enable {
      ${outer}.${inner} = [ finalPackage ];
      programs.myNeovim.finalPackage = finalPackage;
    };
}
