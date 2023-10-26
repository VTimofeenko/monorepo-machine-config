# [[file:../../../new_project.org::*Vtimofeenko customization][Vtimofeenko customization:1]]
{ pkgs, lib, config, inputs', ... }:
let
  kittyHmConfig = import ../kitty { inherit pkgs; };
  inherit (kittyHmConfig.programs.kitty) settings keybindings;
in
{
  programs.kitty = {
    enable = true;
    package = lib.mkForce pkgs.hello; # Not using nix-darwin, no need to manage the app.
    settings =
      settings //
      {
        font_family = "JetBrainsMono Nerd Font";
        tab_separator = ''""'';
        tab_title_template = "{fmt.fg._5c6370}{fmt.bg.default}{fmt.fg._abb2bf}{fmt.bg._5c6370} {title.split()[0]} {fmt.fg._5c6370}{fmt.bg.default} ";
        active_tab_title_template = "{fmt.fg._29b5e8}{fmt.bg.default}{fmt.fg._ffffff}{fmt.bg._29b5e8} {title.split()[0]} {fmt.fg._29b5e8}{fmt.bg.default} ";
        tab_bar_edge = "bottom";
        dynamic_background_opacity = "yes";
        macos_option_as_alt = "yes";
        macos_thicken_font = "0.75";
        background = "#FFFFFF";
        foreground = "#565656";
        selection_background = "none";
        selection_foreground = "none";
        url_color = "#B8B8B8";
        cursor = "none";
        cursor_text_color = "background";
        active_border_color = "#29B5E8";
        inactive_border_color = "#FFFFFF";
        active_tab_background = "#FFFFFF";
        active_tab_foreground = "#565656";
        inactive_tab_background = "#F2F2F2";
        inactive_tab_foreground = "#B8B8B8";
        tab_bar_background = "#F2F2F2";
        color0 = "#FFFFFF";
        color1 = "#D7585D";
        color2 = "#2BA46F";
        color3 = "#FDBE02";
        color4 = "#11567F";
        color5 = "#7D44CF";
        color6 = "#72D3DD";
        color7 = "#565656";
        color8 = "#7F7F7F";
        color9 = "#D7585D";
        color10 = "#2BA46F";
        color11 = "#FDBE02";
        color12 = "#11567F";
        color13 = "#7D44CF";
        color14 = "#72D3DD";
        color15 = "#FFFFFF";
        color16 = "#FF9F36";
        color17 = "#ff00ff";
        color18 = "#F2F2F2";
        color19 = "#29B5E8";
        color20 = "#B8B8B8";
        color21 = "#F2A44E";
      };
    inherit keybindings;
  };
  programs.gh.settings.git_protocol = lib.mkForce "https";
  home.username = "vtimofeenko";
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/vtimofeenko" else "/home/vtimofeenko";

  programs.git = {
    # Null it out first, to be defined in an include file
    userEmail = lib.mkForce null;
  };
  home.packages = [ inputs'.snowcli.packages.default ] ++ (builtins.attrValues { inherit (pkgs) fzf killall bat jq direnv curl wget fd inetutils ripgrep dig unzip htop starship; });
  home.sessionPath =
    if pkgs.stdenv.isDarwin then [
      "/opt/homebrew/Caskroom/miniconda/base/condabin"
      "/nix/var/nix/profiles/default/bin"
      "/Users/vtimofeenko/.nix-profile/bin"
      "/Users/vtimofeenko/Applications/SnowSQL.app/Contents/MacOS"
      "/opt/homebrew/bin"
      "/Users/vtimofeenko/.local/bin"
    ] else [ ];
  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
# Vtimofeenko customization:1 ends here
