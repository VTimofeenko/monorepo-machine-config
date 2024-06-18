/**
  Implementation of pyprland home manager module.
  TODO: Figure out program.settings vs service.settings.
  Both are valid, need some good example from HM repo.

  TODO: reload service on config change `pypr reload`

  TODO: if OK -- upstream to home manager?
*/
{
  pkgs,
  lib,
  config,
  ...
}:
let
  programCfg = config.programs.pyprland;
  srvCfg = config.services.pyprland;

  settingsFormat = pkgs.formats.toml { };

  inherit (lib)
    mkEnableOption
    mkOption
    mkPackageOption
    mkIf
    mkMerge
    types
    ;
in
{
  options =
    let
      commonOpts = {
        package = mkPackageOption pkgs "pyprland" { };
        settings = mkOption {
          type = types.submodule { freeformType = settingsFormat.type; };
          description = "pyprland configuration file";
        };
      };
    in
    {
      programs.pyprland = commonOpts // {
        enable = mkEnableOption "pyprland";
      };
      services.pyprland = commonOpts // {
        enable = mkEnableOption ''
          pyprland user service.

          NOTE: pyprland needs a service running. Use either service.pyprland.enable or start pyprland as in pyprland docs.
        '';
      };
    };

  config = mkMerge [
    (mkIf programCfg.enable {
      home.packages = [ programCfg.package ];
      xdg.configFile."hypr/pyprland.toml".source = settingsFormat.generate "pyprland.toml" programCfg.settings;
    })
    (mkIf srvCfg.enable {
      systemd.user.services.pyprland = {
        Unit = {
          Description = "pyprland service";
          BindsTo = [ "hyprland-session.target" ];
        };
        Service = {
          ExecStart = "${lib.getExe srvCfg.package}";
          # Clean up socket on service exit
          # ExecStopPost = "${pkgs.coreutils}/bin/rm -f /tmp/.pypr-$HYPRLAND_INSTANCE_SIGNATURE/.pyprland.sock";
          # ExecStopPost = "echo $HYPRLAND_INSTANCE_SIGNATURE > /tmp/syu-debug";
          ExecStartPre =
            lib.pipe
              {
                name = "pyprland-cleanup";
                runtimeInputs = [ pkgs.coreutils ];
                text = ''
                  rm -f /tmp/.pypr-"$HYPRLAND_INSTANCE_SIGNATURE"/.pyprland.sock
                '';
              }
              [
                pkgs.writeShellApplication
                lib.getExe
              ];
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    })
  ];
}
