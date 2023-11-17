# Flake module that declares flake.homeManagerModules outputs and how to merge it
{ lib
  # , self
, flake-parts-lib
, moduleLocation
, ...
}:
let
  inherit (lib)
    mapAttrs
    mkOption
    types
    ;
  inherit (flake-parts-lib)
    mkSubmoduleOptions
    ;
in
{
  options = {
    flake = mkSubmoduleOptions {
      homeManagerModules = mkOption {
        type = types.lazyAttrsOf types.unspecified;
        default = { };
        apply = mapAttrs (k: v: { _file = "${toString moduleLocation}#homeManagerModules.${k}"; imports = [ v ]; });
        description = ''
          Home Manager modules.

          You may use this for reusable pieces of configuration, service modules, etc.
        '';
      };
    };
  };
}
