# [[file:../../new_project.org::*Tmux][Tmux:1]]
{ localFlake, inputs }:
{ pkgs, config, lib, ... }:
let
  colorSchemeName = "atlas";
  rendered_color_scheme = with inputs; (base16.outputs.lib { inherit pkgs; lib = pkgs.lib; }).mkSchemeAttrs "${color_scheme}/${colorSchemeName}.yaml";
  mkTmuxConf =
    with builtins; ''
      # Main config
      ${readFile ./tmux.conf}
    '' + (with rendered_color_scheme; (
      let
        default_background = "#" + base00;
        default_foreground = "#" + base07;
        /* helper functions */
        mkbg = _: "bg=#" + _;
        mkfg = _: "fg=#" + _;
      in
      builtins.concatStringsSep "\n" (lib.attrsets.attrValues (lib.attrsets.mapAttrs (k: v: "set -g ${k} \"${toString v}\"") {
        /* Status (background of the pane) */
        "status-interval" = 1;
        "status" = "on";
        "status-style" = "${mkfg base07},${mkbg base00}";
        "message-style" = mkfg base01 + "," + mkbg base0A;
        "message-command-style" = mkfg base01 + "," + mkbg base0A;
        /* Copy mode */
        "mode-style" = "${mkfg base00},${mkbg base0E}";

        /* Panes */
        "pane-border-style" = "${mkfg base04}";
        "display-panes-colour" = "#${base04}";
        "pane-active-border-style" = "${mkfg base0E}";
        "display-panes-active-colour" = "#${base02}";

        /* The name of the session is here */
        "status-left" = "#[${mkfg base00},${mkbg base0E},bold] #S #[${mkfg base0E},${mkbg base00},nobold]";
        /* The format of the window bars that follow the session name */
        "window-status-format" = "#[${mkfg base00},${mkbg base04}] #[${mkfg base07},${mkbg base04}]#I #[${mkfg base07},${mkbg base04}]#W #F #[${mkfg base04},${mkbg base00}]";
        /* Active window. Symbol helps with additional highlighting. */
        "window-status-current-format" = "#[${mkfg base00},${mkbg base02}] #[${mkfg base07},${mkbg base02}]#I #[${mkfg base00},${mkbg base02}] #[${mkfg base07},${mkbg base02}]#W: #F #[${mkfg base02},${mkbg base00}]";

        /* Clock + hostname */
        "status-right" = "#[${mkfg base04},${mkbg base00}]#[${mkfg base07},${mkbg base04}] %b %-d %R #[${mkfg base0C},${mkbg base04}]#[${mkfg base07},${mkbg base0C}] #H ";
        /* bell */
        "window-status-bell-style" = "${mkfg base01},${mkbg base08}";
      }))
    ));
  plugins = with pkgs.tmuxPlugins; [ ];
in
{
  programs.tmux = {
    enable = true;
    /* Commented out, since set in the mkTmuxConf function */
    # terminal = "tmux-256color";
    keyMode = "vi";
    baseIndex = 1;
    escapeTime = 1;
    extraConfig = ''
      ${mkTmuxConf}

      # Plugins
      ${lib.concatStrings (map (x: "run-shell ${x.rtp}\n") plugins)}
    '';
  };
}
# Tmux:1 ends here
