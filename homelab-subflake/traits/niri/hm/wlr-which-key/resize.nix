{
  # niri has no nested keymaps (cf. Hyprland submaps), so wlr-which-key
  # stands in for "resize mode". Invoked as `wlr-which-key resize`, which
  # reads $XDG_CONFIG_HOME/wlr-which-key/resize.yaml (generated below).
  programs.wlr-which-key = {
    enable = true;
    extraMenus.resize =
      let
        resizeKey =
          {
            key,
            desc,
            action,
            change,
          }:
          {
            inherit key desc;
            cmd = ''niri msg action ${action} -- "${change}"'';
            keep_open = true;
          };
      in
      {
        inhibit_compositor_keyboard_shortcuts = true;
        menu =
          [
            {
              key = "h";
              desc = "Shrink column width (10%)";
              action = "set-column-width";
              change = "-10%";
            }
            {
              key = "l";
              desc = "Grow column width (10%)";
              action = "set-column-width";
              change = "+10%";
            }
            {
              key = "j";
              desc = "Shrink window height (10%)";
              action = "set-window-height";
              change = "-10%";
            }
            {
              key = "k";
              desc = "Grow window height (10%)";
              action = "set-window-height";
              change = "+10%";
            }
            {
              key = "H";
              desc = "Shrink column width (50%)";
              action = "set-column-width";
              change = "-50%";
            }
            {
              key = "L";
              desc = "Grow column width (50%)";
              action = "set-column-width";
              change = "+50%";
            }
            {
              key = "J";
              desc = "Shrink window height (50%)";
              action = "set-window-height";
              change = "-50%";
            }
            {
              key = "K";
              desc = "Grow window height (50%)";
              action = "set-window-height";
              change = "+50%";
            }
          ]
          |> map resizeKey;
      };
  };
}
