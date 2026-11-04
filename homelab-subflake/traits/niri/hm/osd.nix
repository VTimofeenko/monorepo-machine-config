/**
  Flashes the keyboard layout name through swayosd when it changes.

  - Listens to `niri msg event-stream`; the initial `KeyboardLayoutsChanged`
    provides the names, `KeyboardLayoutSwitched` provides the index
*/
{ pkgs, lib, ... }:
let
  layoutOsd = pkgs.writeShellApplication {
    name = "niri-layout-osd";
    runtimeInputs = [
      pkgs.niri
      pkgs.jq
      pkgs.swayosd
    ];
    text = ''
      niri msg --json event-stream \
        | jq --unbuffered -nr '
            foreach inputs as $e ({ names: [] };
              if $e.KeyboardLayoutsChanged then
                .names = $e.KeyboardLayoutsChanged.keyboard_layouts.names | .show = null
              elif $e.KeyboardLayoutSwitched then
                .show = .names[$e.KeyboardLayoutSwitched.idx]
              else
                .show = null
              end;
              .show // empty)' \
        | while read -r layout; do
            swayosd-client --custom-message "$layout" --custom-icon input-keyboard || true
          done
    '';
  };
in
{
  systemd.user.services.niri-layout-osd = {
    Unit = {
      Description = "Keyboard layout change OSD";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = lib.getExe layoutOsd;
      Restart = "always";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
