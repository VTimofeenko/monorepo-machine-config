# A set of settings that are common for both modules
{
  pkgs,
  ...
}:
let
  inherit (pkgs.lib)
    getExe
    concatMapStringsSep
    concatStringsSep
    ;
in
rec {
  additionalOptions = [
    "INTERACTIVE_COMMENTS" # Bash-style comments in interactive shell
  ];
  initExtra = concatStringsSep "\n" [
    # Enable all options
    (concatMapStringsSep "\n" (opt: "setopt ${opt}") additionalOptions)
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
    # automatically open files with certain extensions in EDITOR
    (concatMapStringsSep "\n" (ext: "alias -s ${ext}=$EDITOR") [
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
  ];
}
