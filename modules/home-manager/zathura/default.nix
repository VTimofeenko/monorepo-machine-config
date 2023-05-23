# [[file:../../../new_project.org::*Zathura][Zathura:1]]
# Home-manager module for Zathura
{ ... }: {
  programs.zathura = {
    enable = true;
    options = {
      # Allows zathura to use system clipboard
      selection-clipboard = "clipboard";
    };
  };
}
# Zathura:1 ends here
