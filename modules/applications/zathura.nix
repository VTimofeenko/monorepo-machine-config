{ ... }:

{
  home-manager.users.spacecadet = { ... }: {
    programs.zathura = {
      enable = true;
      options = {
        # Allows zathura to use system clipboard
        selection-clipboard = "clipboard";
      };
    };
  };
}
