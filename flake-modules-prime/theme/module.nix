{ theme }:
{ lib, ... }:
let
  inherit (lib.options) mkOption;
in
{
  options = {
    my-colortheme = {
      raw = mkOption {
        description = "Raw color scheme with additional attributes";
        type = lib.types.attrsOf lib.types.anything;
        default = theme.scheme;
      };
      semantic = mkOption {
        description = "Semantic colors with some meaning attached to them";
        type = lib.types.attrsOf lib.types.anything;
        default = theme.semantic;
      };
    };
  };
}
