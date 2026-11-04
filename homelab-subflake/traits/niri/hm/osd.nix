/**
  Flashes keyboard layout and workspace changes through swayosd.

  - Listens to `niri msg event-stream`
  - Layout names come from `KeyboardLayoutsChanged`, the switch from `KeyboardLayoutSwitched`
  - Workspace numbers come from `WorkspacesChanged`, the switch from a focused `WorkspaceActivated`
  - Workspace flash only fires within the same output; moving focus across monitors stays silent
*/
{ pkgs, lib, ... }:
let
  niriOsd = pkgs.writeShellApplication {
    name = "niri-osd";
    runtimeInputs = [
      pkgs.niri
      pkgs.jq
      (pkgs.callPackage ./swayosd-focused.nix { })
    ];
    text = ''
      niri msg --json event-stream \
        | jq --unbuffered -nr '
            foreach inputs as $e ({ names: [], ws: {} };
              .show = null
              | if $e.KeyboardLayoutsChanged then
                  .names = $e.KeyboardLayoutsChanged.keyboard_layouts.names
                elif $e.KeyboardLayoutSwitched then
                  .show = ["input-keyboard", .names[$e.KeyboardLayoutSwitched.idx]]
                elif $e.WorkspacesChanged then
                  .ws = ($e.WorkspacesChanged.workspaces | map({ key: (.id | tostring), value: { idx, output } }) | from_entries)
                  | ($e.WorkspacesChanged.workspaces | map(select(.is_focused)) | first) as $f
                  | if .focused == null and $f then .focused = { id: $f.id, output: $f.output }
                    elif .focused then .focused.output = (.ws[.focused.id | tostring].output // .focused.output)
                    end
                elif $e.WorkspaceActivated.focused then
                  $e.WorkspaceActivated.id as $id
                  | .ws[$id | tostring] as $w
                  | if $w then
                      (if .focused.output == $w.output and .focused.id != $id then
                         .show = ["view-grid", "Workspace \($w.idx)"]
                       end)
                      | .focused = { id: $id, output: $w.output }
                    end
                end;
              .show // empty | @tsv)' \
        | while IFS=$'\t' read -r icon message; do
            swayosd-focused --custom-message "$message" --custom-icon "$icon" || true
          done
    '';
  };
in
{
  systemd.user.services.niri-osd = {
    Unit = {
      Description = "Keyboard layout and workspace change OSD";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = lib.getExe niriOsd;
      Restart = "always";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
