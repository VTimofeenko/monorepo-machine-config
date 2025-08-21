# Home-manager module for Zathura
{
  programs.zathura = {
    enable = true;
    options = {
      # Allows zathura to use system clipboard
      selection-clipboard = "clipboard";
      database = "sqlite";
    };
  };
}
