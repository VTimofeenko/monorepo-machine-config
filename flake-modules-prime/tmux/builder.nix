# Produces my tmux configuration
{ self }:
{ lib, ... }:
let
  scheme = self.data.my-colortheme.scheme |> lib.mapAttrs (_: convertColor);
  semantic = self.data.my-colortheme.semantic |> lib.mapAttrs (_: convertColor);
  convertColor =
    color:
    assert lib.assertMsg (
      !lib.hasPrefix "#" color.HEX
    ) "Color ${color} HEX should not have the '#' prefix ";
    {
      inherit (color) HEX;
      asBg = "bg=#${color.HEX}";
      asFg = "fg=#${color.HEX}";
      "#" = "#${color.HEX}";
    };

  plugins = [ ]; # with pkgs.tmuxPlugins; [ ];
in
{
  tmuxConf = builtins.concatStringsSep "\n" [
    "# Main config"
    (builtins.readFile ./tmux.conf)
    "# Color scheme"
    (
      let
        mkPair = colorLeft: colorRight: "${colorLeft.asFg},${colorRight.asBg}";
      in
      with semantic;
      with scheme;
      {
        # Status (background of the pane)
        "status-interval" = 1;
        "status" = "on";
        "status-style" = mkPair uiStatusFg uiStatusBg;
        "message-style" = mkPair levelErr levelWarn;
        "message-command-style" = mkPair levelErr levelWarn;
        # Copy mode
        "mode-style" = mkPair uiActiveFg uiActiveBg;

        # Panes
        "pane-border-style" = inactiveFrameBorder.asFg;
        "display-panes-colour" = inactiveFrameBorder."#";
        "pane-active-border-style" = activeFrameBorder.asFg;
        "display-panes-active-colour" = activeFrameBorder."#";

        # The name of the session is here
        "status-left" =
          "#[${uiHighlightFg.asFg},${uiHighlightBg.asBg},bold] #S #[${uiHighlightBg.asFg},${uiStatusBg.asBg},nobold]";
        # The format of the window bars that follow the session name
        "window-status-format" =
          "#[${uiStatusBg.asFg},${uiInactiveBg.asBg}] #[${uiInactiveFg.asFg},${uiInactiveBg.asBg}]#I #[${uiInactiveFg.asFg},${uiInactiveBg.asBg}]#W #F #[${uiInactiveBg.asFg},${uiStatusBg.asBg}]";
        # Active window. Symbol helps with additional highlighting.
        "window-status-current-format" =
          "#[${uiStatusBg.asFg},${uiActiveBg.asBg}] #[${uiActiveFg.asFg},${uiActiveBg.asBg}]#I #[${uiActiveFg.asFg},${uiActiveBg.asBg}] #[${uiActiveFg.asFg},${uiActiveBg.asBg}]#W: #F #[${uiActiveBg.asFg},${uiStatusBg.asBg}]";

        # Clock + hostname
        "status-right" =
          "#[${uiInactiveBg.asFg},${uiStatusBg.asBg}]#[${uiInactiveFg.asFg},${uiInactiveBg.asBg}] %b %-d %R #[${uiActiveBg.asFg},${uiInactiveBg.asBg}]#[${uiActiveFg.asFg},${uiActiveBg.asBg}] #H ";
        # bell
        "window-status-bell-style" = "${levelErr.asFg},${uiStatusBg.asBg}";

      }
      |> lib.mapAttrsToList (n: v: ''set -g ${n} "${toString v}"'')
      |> builtins.concatStringsSep "\n"
    )

    "# Plugins"
    (lib.concatStrings (
      map (x: ''
        run-shell ${x.rtp}
      '') plugins
    ))
  ];
}
