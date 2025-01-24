/**
  Sets up cursor mode plugin.

  Behaves like vim. Sets the cursor to '|' when inserting and makes it a block
  when in vim mode.
*/
let
  pluginName = "cursor-mode";
  init = ''
    fpath=(${./.} $fpath)
    autoload -Uz ${pluginName}.zsh && ${pluginName}.zsh
  '';
in
{
  nixosModule = {
    programs.zsh.interactiveShellInit = init;
  };
  homeManagerModule = {
    programs.zsh.initExtra = init;
  };
}
