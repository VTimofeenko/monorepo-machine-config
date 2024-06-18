# [[file:../../../new_project.org::*Pyprland config][Pyprland config:1]]
# Home-manager module for pyprland
{ pkgs, lib, ... }:
let
  droptermClass = "kitty-dropterm";
in
{
  imports = [ ./impl.nix ];
  services.pyprland.enable = true;
  programs.pyprland = {
    enable = true;
    settings = {
      pyprland = {
        plugins = [
          "scratchpads"
          # TODO: setup
          # "expose"
          # TODO: needs engine (some form of dmenu like thing)
          # "fetch_client_menu"
        ];
      };
      scratchpads = {
        "term" = {
          command = "${lib.getExe pkgs.kitty} --class ${droptermClass}";
          animation = "fromTop";
          unfocus = "hide";
        };
      };
    };
  };
  # pypr-specific config
  wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
    bind = $mainMod SHIFT, Return, exec, pypr toggle term
    $dropterm = ^(${droptermClass})$
    windowrule = float,$dropterm
    windowrule = workspace special silent,$dropterm
    windowrule = size 75% 60%,$dropterm
  '';
}
# Pyprland config:1 ends here
