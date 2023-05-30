# [[file:../../../new_project.org::*Pyprland config][Pyprland config:1]]
# Home-manager module for pyprland
{ config, pkgs, lib, pyprland, ... }:
let
  droptermClass = "kitty-dropterm";
in
{
  imports = [
    pyprland.homeManagerModules.default
  ];
  services.pyprland.enable = true;
  programs.pyprland = {
    enable = true;
    extraConfig = {
      pyprland = {
        plugins = [
          "scratchpads"
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
  wayland.windowManager.hyprland.extraConfig =
    lib.mkAfter
      ''
        bind = $mainMod SHIFT, Return, exec, pypr toggle term
        $dropterm = ^(${droptermClass})$
        windowrule = float,$dropterm
        windowrule = workspace special silent,$dropterm
        windowrule = size 75% 60%,$dropterm
      '';
}
# Pyprland config:1 ends here
