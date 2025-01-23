/**
  Configures syntax highlighting in shell.
*/
{ lib, self, ... }:
let
  inherit (self.data.my-colortheme) semantic;

  init =
    [
      # Source
      # https://github.com/zsh-users/zsh-syntax-highlighting/issues/359
      ''
        typeset -gA ZSH_HIGHLIGHT_STYLES
        ZSH_HIGHLIGHT_STYLES[comment]='fg=${semantic.comment.number}'
      ''
    ]
    |> lib.flatten
    |> lib.concatStringsSep "\n";
in
{
  nixosModule = {
    programs.zsh = {
      interactiveShellInit = init;
      syntaxHighlighting.enable = true;
    };
  };
  homeManagerModule = {
    programs.zsh = {
      initExtra = init;
      syntaxHighlighting.enable = true;
    };
  };
}
