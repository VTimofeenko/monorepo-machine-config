{ ... }:

{
  # Allows zathura to use system clipboard
  environment.etc."zathurarc".text = ''
    set selection-clipboard clipboard
  '';
}
