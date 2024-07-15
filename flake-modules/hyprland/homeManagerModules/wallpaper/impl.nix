{
  pkgs,
  lib,
  config,
  ...
}:
let
  target = "graphical-session.target";
  inherit (lib)
    mkEnableOption
    mkIf
    mkPackageOption
    mkOption
    types
    pipe
    ;
  cfg = config.services.swww;
in
{
  options.services.swww = {
    enable = mkEnableOption "swww";
    wallpaperPath = mkOption {
      description = "Directory with wallpaper files";
      type = types.path;
    };
    package = mkPackageOption pkgs "swww" { };
  };
  config = mkIf cfg.enable {
    systemd.user = {
      services = {
        swww = {
          Unit = {
            Description = "Wallpaper daemon";
            PartOf = [ target ];
            After = [ target ];
            ConditionEnvironment = "WAYLAND_DISPLAY";
          };
          Service = {
            Type = "simple";
            ExecStart = "${cfg.package}/bin/swww-daemon";
            Restart = "always";
          };
          Install = {
            WantedBy = [ target ];
          };
        };
        set-random-wallpaper = {
          Unit = {
            Description = "random wallpaper setter";
            Requires = [ "swww.service" ];
            After = [ "swww.service" ];
            ConditionEnvironment = "WAYLAND_DISPLAY";
          };
          Service = {
            Type = "oneshot";
            Environment = "WALLPAPER_PATH=${cfg.wallpaperPath}";
            ExecStart =
              pipe
                {
                  name = "set-random-wallpaper";
                  runtimeInputs = [
                    cfg.package # provides "swww"
                    pkgs.coreutils-full # provides "shuf" and "head"
                    pkgs.fd # fast search
                  ];
                  text = # bash
                    ''
                      WALLPAPER=$(fd --absolute-path --full-path "''${WALLPAPER_PATH}" | shuf | head -n1)
                      swww img "''${WALLPAPER}"
                    '';
                }
                [
                  pkgs.writeShellApplication
                  lib.getExe
                ];
          };
        };
      };

      timers.set-random-wallpaper = {

        Unit.Description = "random wallpaper setter";

        Timer = {
          OnCalendar = "hourly";
          Unit = "set-random-wallpaper.service";
        };

        Install.WantedBy = [ "timers.target" ];
      };
    };
  };
}
