/**
  General configuration that did not fit anywhere else
*/
{ lib, ... }:
let
  opts = [
    "INTERACTIVE_COMMENTS" # Bash-style comments in interactive shell
  ];
  init =
    [
      # Enable options
      (opts |> map (it: "setopt ${it}"))
      ''
        # Word Navigation shortcuts
        bindkey "^A" vi-beginning-of-line
        bindkey "^E" vi-end-of-line
        bindkey "^F" end-of-line

        # ctrl+arrow for word jupming
        bindkey "^[[1;5C" forward-word
        bindkey "^[[1;5D" backward-word

        # alt+f forward a word
        bindkey "^[f" forward-word
        # alt+b back a word
        bindkey "^[b" backward-word
        # working backspace
        bindkey -v '^?' backward-delete-char
      ''
      # Vim keys in tab complete menu
      ''
        zmodload zsh/complist
        bindkey -M menuselect 'h' vi-backward-char
        bindkey -M menuselect 'k' vi-up-line-or-history
        bindkey -M menuselect 'l' vi-forward-char
        bindkey -M menuselect 'j' vi-down-line-or-history
        bindkey -M menuselect '^ ' accept-line

        # Add entry by "+" but do not exit menuselect
        bindkey -M menuselect "+" accept-and-menu-complete
      ''
      # Automatically open files with certain extensions in EDITOR
      (lib.concatMapStringsSep "\n" (ext: "alias -s ${ext}=$EDITOR") [
        "nix"
        "ncl"
        "md"
        "yml"
        "yaml"
        "sql"
        "lua"
        "toml"
        "json"
        "rs"
        "py"
      ])
      # Debug stuff
      ''
        _debug_show_completions(){
          for command completion in ''${(kv)_comps:#-*(-|-,*)}
          do
            printf "%-32s %s\n" $command $completion
          done | sort | less
        }
      ''

    ]
    |> lib.flatten
    |> lib.concatLines;
in
{
  nixosModule = {
    programs.zsh = {
      enable = true;
      interactiveShellInit = init;
    };
  };
  homeManagerModule = {
    programs.zsh = {
      enable = true;
      initContent = init;
      # Start in VI insert mode
      defaultKeymap = "viins";
      # Move the dotfiles to `~/.config` -- unclutter home directory
      dotDir = ".config/zsh";
    };
  };
}
