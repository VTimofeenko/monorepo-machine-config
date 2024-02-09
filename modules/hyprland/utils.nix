# [[file:../../new_project.org::*Hyprland utils][Hyprland utils:1]]
pkgs:
let
  inherit (pkgs) lib;
in
{
  scratchpad-terminal = pkgs.writeShellApplication {
    name = "scratchpad-terminal";
    runtimeInputs = [
      pkgs.hyprland
      pkgs.kitty
    ];
    text = ''
      TERM="${lib.getExe pkgs.kitty}"
      TERM_TITLE="dropdown-terminal"
      GET_CLIENTS_CMD="hyprctl clients"
      DISPATCHER_EXEC_CMD=(hyprctl dispatch "exec [workspace special:''${TERM_TITLE} silent;float]" "''${TERM} -T ''${TERM_TITLE} ${lib.getExe pkgs.btop}")
      SCRATCHPAD_TOGGLE_CMD="hyprctl dispatch togglespecialworkspace ''${TERM_TITLE}"  # swaymsg scratchpad show

      is_terminal_running() {
          if ''${GET_CLIENTS_CMD} | grep "''${TERM_TITLE}" >/dev/null; then
              return 0
          else
              return 1
          fi
      }
      if ! is_terminal_running; then
          "''${DISPATCHER_EXEC_CMD[@]}" >/dev/null 2>&1
          sleep 0.35
          ''${SCRATCHPAD_TOGGLE_CMD} >/dev/null 2>&1
      else
          ''${SCRATCHPAD_TOGGLE_CMD} >/dev/null 2>&1
      fi
    '';
  };
}
# Hyprland utils:1 ends here
