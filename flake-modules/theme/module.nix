{ lib, pkgs, ... }:
let
  inherit (lib.types) attrsOf str;
  inherit (lib.options) mkOption;

  /* A derivation is needed for using nickel to build the needed values */
  themePackage = pkgs.callPackage ./packages/theme/package.nix { inherit (pkgs) stdenv nickel lib; };

  theme = lib.pipe (themePackage + "/theme.json") [ builtins.readFile builtins.fromJSON ];
in
{
  options = {
    my-colortheme = {
      raw = mkOption {
        description = "Raw color scheme with additional attributes";
        type = attrsOf (attrsOf str);
        default = theme.scheme;
      };
      semantic = mkOption {
        description = "Semantic colors with some meaning attached to them";
        type = attrsOf (attrsOf str);
        default = theme.semantic;
      };
    };
  };
}
