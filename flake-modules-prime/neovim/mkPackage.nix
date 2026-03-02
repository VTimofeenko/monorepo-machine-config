# This function consumes a module, applies provided config and produces a package
{
  modConfig, # Config to be evaluated for the module
  moduleToEval,
  lib,
  pkgs,
}:
let
  baseModConfig =
    (lib.evalModules {
      modules = [
        { _module.check = false; } # This skips some checks that can be (probably) safely bypassed
        moduleToEval
      ];
      specialArgs = {
        inherit pkgs lib;
        # config = { };
      };
    }).config;

  endConfig = lib.recursiveUpdate baseModConfig { programs.myNeovim = modConfig; };
in
((builtins.head moduleToEval.imports) {
  inherit pkgs lib;
  config = endConfig;
}).config.content.programs.myNeovim.package
