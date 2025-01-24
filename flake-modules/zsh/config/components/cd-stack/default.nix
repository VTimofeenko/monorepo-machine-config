/**
  Sets up `cd-stack` plugin.

  Keeps track of the directory history and allows jumping back and forth using
  `cd +1`, `cd +2` etc.
*/
let
  pluginName = "cd-stack";
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
