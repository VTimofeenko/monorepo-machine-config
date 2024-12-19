/**
  Home-manager module that configures per-window rules that don't have a better place to live.
*/
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
      # add tag to classes
      (map (class: "tag +${settings.flyOut.tagName}, class:(${class})") settings.flyOut.classes)
      # add tag to titles
      ++ (map (title: "tag +${settings.flyOut.tagName}, title:(${title})") settings.flyOut.titles)
      # implement the window rules for tag
      ++ (map (rule: "${rule}, tag:${settings.flyOut.tagName}") [
        "float"
        "size 30% 20%"
        "move 35% 10%"
        "stayfocused"
        "dimaround"
      ]);
  };
}
