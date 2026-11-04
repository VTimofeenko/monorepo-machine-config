{
  # Stand-in for Hyprland's `submap = toggle`. Invoked as
  # `wlr-which-key toggle`, which reads
  # $XDG_CONFIG_HOME/wlr-which-key/toggle.yaml (generated below).
  #
  # Hyprland's toggle submap also had:
  # - `F` (toggle floating): already a direct niri bind (Mod+V), no menu
  #   entry needed.
  # - `P` (pin window): niri has no pinned/sticky-window concept, dropped.
  #
  # Add more toggles here as they come up.
  programs.wlr-which-key.extraMenus.toggle = {
    menu = [
      {
        key = "n";
        desc = "Toggle notification panel";
        cmd = "swaync-client --toggle-panel --skip-wait";
      }
    ];
  };
}
