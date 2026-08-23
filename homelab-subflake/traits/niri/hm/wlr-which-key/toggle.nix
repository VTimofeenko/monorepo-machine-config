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
        desc = "Restore last notification";
        # mako only supports restoring the most recently dismissed
        # notification, not browsing/picking from history.
        cmd = "makoctl restore";
      }
    ];
  };
}
