/**
  Sets up line editing in zsh.

  By hitting `Esc` and then `jk`, special `vim` is started. This `vim`
  configuration has some basic plugins (for a very quick start) and overrides
  the path completion so that it stays in the current directory.

  By default, edit-command-line creates the editable script in `/tmp` and
  relative path completions would be working as if the file was in that
  directory (well, it is). Using a small override for the completion sources
  (see Lua code in `my-edit-command-line`) this module tells completions to
  treat the original location as source for relative paths.
*/
{
  lib,
  self,
  pkgs,
  ...
}:
let
  init = ''
    fpath=(${./.} $fpath)
    bindkey -v

    autoload my-edit-command-line; zle -N my-edit-command-line
    bindkey -M vicmd jk my-edit-command-line  # jk chord to edit the current line
    export CMD_EDITOR="${lib.getExe' self.packages.${pkgs.stdenv.system}.vim-minimal "nvim"}"
  '';
in
{
  nixosModule = {
    programs.zsh.interactiveShellInit = init;
  };
  homeManagerModule = {
    programs.zsh.initContent = init;
  };
}
