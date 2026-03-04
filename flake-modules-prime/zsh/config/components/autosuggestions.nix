/**
  Configures auto-suggestions in shell.
*/
{
  nixosModule = {
    programs.zsh.autosuggestions.enable = true;
  };
  homeManagerModule = {
    programs.zsh.autosuggestion.enable = true;
  };
}
