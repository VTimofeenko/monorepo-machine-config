# [[file:../../new_project.org::*Hyprland utils][Hyprland utils:1]]
pkgs:
{
  scratchpad-terminal = pkgs.writeShellApplication {
    name = "scratchpad-terminal";
    runtimeInputs = [ pkgs.hyprland pkgs.kitty ];
    text = builtins.readFile ./utils/scratchpad-terminal;
  };
}
# Hyprland utils:1 ends here
