/**
  Sets up bookmarks plugin.

  This plugin works by saving a bookmark (`bookmark .`) and then changing
  directory to it using `@@`.
*/
let
  pluginName = "bookmarks";
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
