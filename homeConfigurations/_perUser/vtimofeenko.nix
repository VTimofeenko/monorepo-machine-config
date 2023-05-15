{ pkgs, lib, config, ... }:
{
  programs.kitty.package = lib.mkForce pkgs.hello; # Workaround for kitty not getting needed opengl on arch
  home.username = "vtimofeenko";
  home.homeDirectory = "/Users/vtimofeenko";
  programs.kitty.settings =
    {
      extraConfig =
        ''
          font_family      JetBrainsMono Nerd Font Mono
          cursor_blink_interval 0
          inactive_text_alpha 0.85
          tab_bar_margin_width      9
          tab_bar_margin_height     2 2
          tab_bar_style             separator
          tab_bar_min_tabs          0
          tab_separator             ""
          tab_title_template        "{fmt.fg._5c6370}{fmt.bg.default}{fmt.fg._abb2bf}{fmt.bg._5c6370} {title.split()[0]} {fmt.fg._5c6370}{fmt.bg.default} "
          active_tab_title_template "{fmt.fg._29b5e8}{fmt.bg.default}{fmt.fg._ffffff}{fmt.bg._29b5e8} {title.split()[0]} {fmt.fg._29b5e8}{fmt.bg.default} "
          tab_bar_edge bottom
          background_opacity 0.95
          dynamic_background_opacity yes
          macos_option_as_alt yes
          macos_thicken_font 0.75
          map kitty_mod+enter launch --cwd=current
          background #FFFFFF
          foreground #565656
          selection_background none
          selection_foreground none
          url_color #B8B8B8
          cursor none
          cursor_text_color background
          active_border_color #29B5E8
          inactive_border_color #FFFFFF
          active_tab_background #FFFFFF
          active_tab_foreground #565656
          inactive_tab_background #F2F2F2
          inactive_tab_foreground #B8B8B8
          tab_bar_background #F2F2F2
          color0 #FFFFFF
          color1 #D7585D
          color2 #2BA46F
          color3 #FDBE02
          color4 #11567F
          color5 #7D44CF
          color6 #72D3DD
          color7 #565656
          color8 #7F7F7F
          color9 #D7585D
          color10 #2BA46F
          color11 #FDBE02
          color12 #11567F
          color13 #7D44CF
          color14 #72D3DD
          color15 #FFFFFF
          color16 #FF9F36
          color17 #ff00ff
          color18 #F2F2F2
          color19 #29B5E8
          color20 #B8B8B8
          color21 #F2A44E
        '';

    };
}
