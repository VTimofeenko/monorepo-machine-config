# home-manager module for swayimg
# Dup of https://github.com/nix-community/home-manager/pull/5651
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.swayimg;
  settingsFormat = pkgs.formats.ini { };
  inherit (lib)
    mkEnableOption
    mkOption
    mkPackageOption
    types
    ;
in
{
  options.programs.swayimg = {
    enable = mkEnableOption "swayimg";

    settings = mkOption {
      type = types.submodule { freeformType = settingsFormat.type; };
      description = ''
        swayimg configuration. See <https://github.com/artemsen/swayimg/blob/master/extra/swayimgrc> for the default and example
      '';
      default = { };
    };

    package = mkPackageOption pkgs "swayimg" { };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."swayimg/config".source = settingsFormat.generate "config" cfg.settings;
  };
}
