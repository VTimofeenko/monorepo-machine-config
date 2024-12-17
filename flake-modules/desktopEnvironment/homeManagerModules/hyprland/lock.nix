/**
  Home manager module that configures session locking.
*/
{
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  # Things that are often configured (or are expected to be so) go here.
  settings = {
    hyprctl = "${osConfig.programs.hyprland.package}/bin/hyprctl";
    # list of lists. Inner lists represent commands with flags
    lockCmd =
      [
        # TODO: lang switcher goes here
        [
          (lib.getExe pkgs.swaylock)
          "--daemonize"
          "--show-failed-attempts"
          "--show-keyboard-layout"
          "--color 000000"
        ]
      ]
      |> map (lib.concatStringsSep " ")
      |> lib.concatStringsSep " && ";
  };

  inherit (settings) hyprctl lockCmd;
in
{
  # Idle configuration: lock after inactivity
  services.swayidle = {
    enable = true;
    systemdTarget =
      assert lib.assertMsg osConfig.programs.uwsm.enable
        ''This setting relies on uwsm being used to wrap hyprland session.'';
      # This is a bit brittle; exposes the way uwsm generates the session name
      "wayland-session@hyprland\x2duwsm.desktop.target";

    events = [
      {
        event = "after-resume";
        command = "${hyprctl} dispatch dpms on";
      }
      {
        event = "lock";
        command = lockCmd;
      }
      {
        event = "before-sleep";
        command = lockCmd;
      }
    ];

    timeouts = [
      {
        timeout = 300;
        command = "${hyprctl} dispatch dpms off";
      }
      {
        timeout = 303;
        command = lockCmd;
      }
    ];
  };

  wayland.windowManager.hyprland.myBinds =
    let
      srvLib = import ./binds/lib.nix { inherit lib; };
    in
    {
      "${srvLib.Control}+Q" = {
        mod = "$mainMod";
        dispatcher = "exec";
        description = "Launch terminal emulator";
        # I think the way this works is that it dispatches "lock" event, which
        # then makes swayidle handle that event
        arg = "loginctl lock-session";
      };
    };

  # What the DE does DPMS-wise.
  wayland.windowManager.hyprland.settings.misc = {
    # If DPMS is set to off, wake up the monitors if the mouse moves.
    mouse_move_enables_dpms = true;
    # If DPMS is set to off, wake up the monitors if a key is pressed.
    key_press_enables_dpms = true;
  };
}
