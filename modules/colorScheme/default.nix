# NixOS module that configures base16 + my custom color scheme
{ lib, ... }:
let
  inherit (lib.types) attrsOf str;
  inherit (lib.options) mkOption;
in
{
  options = {
    rawColorScheme = mkOption {
      description = "Raw color scheme with additional attributes";
      type = attrsOf str;
    };
    semanticColorScheme = mkOption {
      description = "Semantic colors with some meaning attached to them";
      type = attrsOf str;
    };
  };
  config = rec {
    # Needs base16 module imported
    scheme = import ./assets/modus_custom.nix;
    rawColorScheme = import ./assets/modus_custom.nix;
    semanticColorScheme = with rawColorScheme; {
      activeFrameBorder = cyan-intense;
      inactiveFrameBorder = border-mode-line-inactive;
      levelInfo = color4;
      levelWarn = color3;
      levelErr = color1;
      comment = color7;
    };
  };
}
