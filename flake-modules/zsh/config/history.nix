/**
  Configures shell history.

  Features:
  - History is shared between sessions
  - Duplicates are ignored
  - (bash-like) ignore commands prefixed with space
  - Courtesy of `fzf`: shell reverse search is fuzzy

  This partially re-implements the great home-manager zsh module. This was necessary to make these settings also apply to NixOS module

  TODO: `atuin` integration?
*/
{ lib, pkgs, ... }:
let
  settings = rec {
    histSize = 9999; # Stored in memory during session runtime
    saveHist = histSize; # How many lines to keep in history
    histFile = "$XDG_STATE_HOME/zsh_history"; # `$XDG_STATE_HOME` is chosen because I treat history as durable
    ignorePatterns = [
      "rm *"
      "# *" # I don't care about full-line comments
      "k" # standalone "k" is usually mistyped up arrow
      "l[alsh]#( *)" # Ignore ls commands
    ];
  };

  opts = [
    "BANG_HIST" # Log `!!`-like commands
    "INC_APPEND_HISTORY" # Write to the history file immediately, not when the shell exits.
    "HIST_VERIFY" # Don't execute immediately upon history expansion.
    "HIST_FCNTL_LOCK" # Enable `fcntl` syscall for saving history
    "HIST_IGNORE_ALL_DUPS" # If a new command line being added to the history list duplicates an older one, the older command is removed from the list (even if it is not the previous event).
    "HIST_REDUCE_BLANKS" # Remove extra blanks
    "HIST_EXPIRE_DUPS_FIRST" # Expire duplicates first
    "HIST_IGNORE_SPACE" # Don't save in history if command has space in front of it
    "EXTENDED_HISTORY" # Save timestamp in the history
    "SHARE_HISTORY" # Share history between sessions
  ];

  init =
    [
      # Turn settings into string
      ''
        HISTSIZE=${toString settings.histSize}
        SAVEHIST=${toString settings.saveHist}
        HISTFILE="${settings.histFile}"
        HISTORY_IGNORE=${lib.escapeShellArg "(${lib.concatStringsSep "|" settings.ignorePatterns})"}

        mkdir -p "$(dirname "$HISTFILE")"
      ''
      # Enable options
      (opts |> map (it: "setopt ${it}"))
      # `fzf` bindings take over the `ctrl-R` shortcut
      "source ${pkgs.fzf}/share/fzf/key-bindings.zsh"
    ]
    |> lib.flatten
    |> lib.concatStringsSep "\n";
in
{
  nixosModule = {
    programs.zsh.interactiveShellInit = init;
  };
  homeManagerModule = {
    programs.zsh.initExtra = init;
  };
}
