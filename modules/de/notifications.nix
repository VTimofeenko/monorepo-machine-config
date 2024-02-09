# [[file:../../new_project.org::*Notification daemon][Notification daemon:1]]
# Home-manager module for swaync
{ pkgs, lib, ... }:
{
  /* Removed piece
        "scripts": {
          "example-script": {
            "exec": "echo 'Do something...'",
            "urgency": "Normal"
          },
          "example-action-script": {
            "exec": "echo 'Do something actionable!'",
            "urgency": "Normal",
            "run-on": "action"
          }
        },
  */
  xdg.configFile."swaync/config.json".text =
    # Taken from swaync 0.8.0
    ''
      {
        "$schema": "/etc/xdg/swaync/configSchema.json",
        "positionX": "right",
        "positionY": "top",
        "layer": "top",
        "cssPriority": "application",
        "control-center-margin-top": 0,
        "control-center-margin-bottom": 0,
        "control-center-margin-right": 0,
        "control-center-margin-left": 0,
        "notification-icon-size": 64,
        "notification-body-image-height": 100,
        "notification-body-image-width": 200,
        "timeout": 10,
        "timeout-low": 5,
        "timeout-critical": 0,
        "fit-to-screen": true,
        "control-center-width": 500,
        "control-center-height": 600,
        "notification-window-width": 500,
        "keyboard-shortcuts": true,
        "image-visibility": "when-available",
        "transition-time": 200,
        "hide-on-clear": false,
        "hide-on-action": true,
        "scripts": {},
        "script-fail-notify": true,
        "notification-visibility": {
          "example-name": {
            "state": "muted",
            "urgency": "Low",
            "app-name": "Spotify"
          }
        },
        "widgets": [
          "inhibitors",
          "title",
          "dnd",
          "notifications"
        ],
        "widget-config": {
          "inhibitors": {
            "text": "Inhibitors",
            "button-text": "Clear All",
            "clear-all-button": true
          },
          "title": {
            "text": "Notifications",
            "clear-all-button": true,
            "button-text": "Clear All"
          },
          "dnd": {
            "text": "Do Not Disturb"
          },
          "label": {
            "max-lines": 5,
            "text": "Label Text"
          },
          "mpris": {
            "image-size": 96,
            "image-radius": 12
          }
        }
      }
    '';
  systemd.user.services.swaync =
    let
      target = "graphical-session.target";
    in
    {
      Unit = {
        Description = "Sway notification center";
        PartOf = [ target ];
        After = [ target ];
        # BindsTo = [ target ]; # TODO: needed?
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe pkgs.swaynotificationcenter}";
        Restart = "always";
      };
      Install = {
        WantedBy = [ target ];
      };
    };
}
# Notification daemon:1 ends here
