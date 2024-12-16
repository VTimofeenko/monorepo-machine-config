# NixOS module to enable hyprland and adjacent packages
{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };
}
