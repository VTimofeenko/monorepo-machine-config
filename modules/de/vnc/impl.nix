/**
  Sets up a headless display with wayvnc.

  TODO:
  4. Add nftables rule
*/
{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.services.my-wayvnc;
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  settingsFormat = pkgs.formats.keyValue { };

  # Impl-related
  configFile = settingsFormat.generate "wayvnc-config" cfg.settings;

  hyprctl = config.wayland.windowManager.hyprland.package + "/bin/hyprctl";

  outputProps = {
    name = "wayvncOut";
    mode = "2360x1640@60";
    pos = "2256x0";
    scale = "2";
  };

  setup-output = pkgs.writeShellApplication {
    name = "setup-output";

    runtimeInputs = [ ];

    text = ''
      # This is idempotent provided that the output name is specified
      "${hyprctl}" output create headless ${outputProps.name}

      "${hyprctl}" keyword monitor "${outputProps.name},${outputProps.mode},${outputProps.pos},${outputProps.scale}"
    '';
  };

  run-wayvnc = pkgs.writeShellApplication {
    name = "run-wayvnc";

    runtimeInputs = [ pkgs.wayvnc ];

    text = ''
      sleep 5 # Looks like there's some race happening?
      WAYLAND_DISPLAY=wayland-1 wayvnc --config=${configFile} --log-level=debug --output=${outputProps.name}
    '';
  };

  teardown-output = pkgs.writeShellApplication {
    name = "teardown-output";

    runtimeInputs = [ ];

    text = ''
      "${hyprctl}" output remove ${outputProps.name}
    '';
  };
in
{
  options.services.my-wayvnc = {
    enable = mkEnableOption "my VNC service";
    settings = mkOption {
      type = types.submodule { freeformType = settingsFormat.type; };
      description = "wayvnc config file";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.my-wayvnc = {
      Unit.Description = "Headless VNC";
      Unit.ConditionEnvironment = "WAYLAND_DISPLAY";
      Service = {
        ExecStartPre = lib.getExe setup-output;
        ExecStart = lib.getExe run-wayvnc;
        ExecStopPost = lib.getExe teardown-output;
      };
    };

    xdg.configFile."wayvnc/config".source = configFile;
  };
}
