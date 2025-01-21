# [[file:../../../new_project.org::*Kitty][Kitty:1]]
_: {
  programs.kitty = {
    enable = true;
    themeFile = "Modus_Vivendi_Tinted";
    settings = {
      cursor_blink_interval = 0;
      background_opacity = "0.95";
      inactive_text_alpha = "0.85";
      cursor = "none";
      enable_audio_bell = false;
      tab_bar_margin_width = 9;
      tab_bar_margin_height = "2 2";
      tab_bar_style = "separator";
      tab_bar_min_tabs = 2;
      tab_bar_edge = "bottom";
      tab_title_template = "{fmt.fg.white} {title.split()[0]} ";
      active_tab_title_template = "{fmt.noitalic}{fmt.bg.black}{fmt.fg.white} {title.split()[0]} ";
      # Make vim the scollback pager to copy back and forth
      # Also see https://github.com/mikesmithgh/kitty-scrollback.nvim
      scrollback_pager = "nvim -c ':lua KITTY_SCROLLBACK(INPUT_LINE_NUMBER, CURSOR_LINE, CURSOR_COLUMN)' - ";
      font_size = 9;
    };
    keybindings = {
      # Opens a new Kitty window in the current working directory
      "kitty_mod+enter" = "launch --cwd=current";
      "kitty_mod+i" = "set_tab_title";
      # Detach current window and ask where to move
      "kitty_mod+d" = "detach_window ask";
      "cmd+t" = "new_tab";
    };
  };
}
# Kitty:1 ends here
