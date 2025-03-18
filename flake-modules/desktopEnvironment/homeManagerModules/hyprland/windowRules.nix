/**
  Home-manager module that configures per-window rules that don't have a better place to live.
*/
{ lib, ... }:
let
  settings.flyOut = {
    classes = [
      "pinentry-qt"
      "xdg-desktop-portal-gtk"
    ];
    titles = [ "Open File" ];
    tagName = "flyout";
  };

in
{
  wayland.windowManager.hyprland.settings = {
    # "Flyout" is effectively a modal that should be created in the center top of the screen.
    windowrulev2 =
      [
        # Assign the tags
        (settings.flyOut.classes |> map (class: "tag +${settings.flyOut.tagName}, class:(${class})"))
        (settings.flyOut.titles |> map (title: "tag +${settings.flyOut.tagName}, title:(${title})"))
        # OpenSnitch, but only the prompt
        "tag +${settings.flyOut.tagName}, class:(opensnitch_ui), title:(OpenSnitch v.*)"
        # Implement the tag window rules
        (map (rule: "${rule}, tag:${settings.flyOut.tagName}") [
          "float"
          "size 30% 20%"
          "move 35% 10%"
          "stayfocused"
          "dimaround"
        ])
      ]
      |> lib.flatten;
  };
}
