/**
  Configures paste settings.
*/
{ lib, ... }:
let
  pasteSettings = [
    # Escape URLs when pasting
    ''
      # Automatically escape urls when pasting
      autoload -Uz url-quote-magic
      zle -N self-insert url-quote-magic
      autoload -Uz bracketed-paste-magic
      zle -N bracketed-paste bracketed-paste-magic''
    # Using zsh highlighting with long paths (like nix store) can be slow. This fixes it.
    ''
      # found https://gist.github.com/magicdude4eva/2d4748f8ef3e6bf7b1591964c201c1ab
      pasteinit() {
        OLD_SELF_INSERT=''${''${(s.:.)widgets[self-insert]}[2,3]}
        zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
      }

      pastefinish() {
        zle -N self-insert $OLD_SELF_INSERT
      }
      zstyle :bracketed-paste-magic paste-init pasteinit
      zstyle :bracketed-paste-magic paste-finish pastefinish''
  ];

  init = pasteSettings |> lib.concatLines;
in
{
  nixosModule = {
    programs.zsh.interactiveShellInit = init;
  };
  homeManagerModule = {
    programs.zsh.initContent = init;
  };
}
