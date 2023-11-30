# Home-manager module for swww
{ nixpkgs-unstable, pkgs, ... }:
let
  pkgs-unstable = nixpkgs-unstable.legacyPackages.${pkgs.system};
  target = "graphical-session.target";
in
{
  systemd.user = {
    services = {
      swww =
        {
          Unit = {
            Description = "Wallpaper daemon";
            PartOf = [ target ];
            After = [ target ];
            ConditionEnvironment = "WAYLAND_DISPLAY";
          };
          Service = {
            Type = "simple";
            ExecStart = "${pkgs-unstable.swww}/bin/swww-daemon";
            Restart = "always";
          };
          Install = {
            WantedBy = [ target ];
          };
        };
      set-random-wallpaper = {
        Unit = {
          Description = "random wallpaper setter";
          After = [ "swww.service" ];
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        Service = {
          Type = "oneshot";
          ExecStart = (pkgs.writeShellApplication {
            name = "set-random-wallpaper";
            runtimeInputs = [ pkgs-unstable.swww pkgs.coreutils-full pkgs.fd ];
            text =
              ''
              WALLPAPER=$(fd --absolute-path --full-path ~/Pictures/Wallpapers/ | shuf | head -n1)
              swww img "''${WALLPAPER}"
              '';
            }) + "/bin/set-random-wallpaper";
        };
        Install = {
          WantedBy = [ target ];
        };
      };
    };

    timers.set-random-wallpaper = {
      Unit = { Description = "random wallpaper setter"; };
      Timer = {
        OnCalendar = "hourly";
        Unit = "set-random-wallpaper.service";
      };
      Install = { WantedBy = [ "timers.target" ]; };
    };
  };
}
