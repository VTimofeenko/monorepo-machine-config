# NixOS module that configures my custom neovim package system-wide
{ localFlake# Reference to the flake
, mode# "homeManager" or "nixOS". Since the code is essentially the same, the difference is just a matter of paths
}:
{ pkgs, config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf assertMsg;
  cfg = config.programs.myNvim;
  localPkgs' = localFlake.packages.${pkgs.stdenv.system};
  # Decide where to add the packages
  outer = if mode == "homeManager" then "home" else "environment";
  inner = if mode == "homeManager" then "packages" else "systemPackages";
in
{
  # TODO: proper opts for plugins and init lua
  options.programs.myNvim = {
    enable = mkEnableOption "My neovim with plugins";
    withLangServers = mkEnableOption "Enable language server plugins";
  };
  config = mkIf cfg.enable {
    ${outer}.${inner} = assert assertMsg (config.programs.neovim.enable == false) "This module is not compatible with the standard neovim module";
      [ (if cfg.withLangServers then localPkgs'.vimWithLangs else localPkgs'.vim) ];
  };
}
