/**
  Home-manager module that configures per-window rules that don't have a better place to live.
*/
{ lib, ... }:
let
  settings.flyOut = {
    classes = [
      "org.gnupg.pinentry-qt"
      "xdg-desktop-portal-gtk"
    ];
    titles = [
      "Open File"
      ".*wants to save" # Odd brave's behavior
      ".*wants to open" # Odd brave's behavior
    ];
    tagName = "flyout";
  };

in
{
  wayland.windowManager.hyprland.settings = {
    # "Flyout" is effectively a modal that should be created in the center top of the screen.
    windowrule =
      [
        # Assign the tags
        (settings.flyOut.classes |> map (class: "tag +${settings.flyOut.tagName}, match:class (${class})"))
        (settings.flyOut.titles |> map (title: "tag +${settings.flyOut.tagName}, match:title (${title})"))
        # OpenSnitch, but only the prompt
        "tag +${settings.flyOut.tagName}, match:class (opensnitch_ui), match:title (OpenSnitch v.*)"
        "float on, size (monitor_w*0.3) (monitor_h*0.2), move ((monitor_w*0.35)) ((monitor_h*0.1)), stay_focused on, dim_around on, match:tag ${settings.flyOut.tagName}"
      ]
      |> lib.flatten;
  };
}
