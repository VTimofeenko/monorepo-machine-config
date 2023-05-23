# [[file:../../../new_project.org::*zsh (home-manager)][zsh (home-manager):2]]
# home-manager clone of the original zsh module
{ pkgs, config, lib, ... }:
let
  zshOptionsToSet = [
    "INTERACTIVE_COMMENTS" # allow bash-style comments
    # history
    "BANG_HIST" # enable logging !!-like commands
    "EXTENDED_HISTORY" # Write the history file in the ":start:elapsed;command" format.
    "INC_APPEND_HISTORY" # Write to the history file immediately, not when the shell exits.
    "SHARE_HISTORY" # Share history between all sessions.
    "HIST_EXPIRE_DUPS_FIRST" # Expire duplicate entries first when trimming history.
    "HIST_IGNORE_DUPS" # Don't record an entry that was just recorded again.
    "HIST_IGNORE_ALL_DUPS" # Delete old recorded entry if new entry is a duplicate.
    "HIST_FIND_NO_DUPS" # Do not display a line previously found.
    "HIST_IGNORE_SPACE" # Don't record an entry starting with a space.
    "HIST_SAVE_NO_DUPS" # Don't write duplicate entries in the history file.
    "HIST_REDUCE_BLANKS" # Remove superfluous blanks before recording entry.
    "HIST_VERIFY" # Don't execute immediately upon history expansion.
    "HIST_FCNTL_LOCK" # enable fcntl syscall for saving history
    # cd management
    "AUTO_CD" # automatically cd into directory
  ];
in
{
  home.packages = builtins.attrValues {
    inherit (pkgs) fzf killall bat jq direnv curl wget fd inetutils ripgrep lsof dig unzip htop;
  };
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    enableSyntaxHighlighting = true;
    autocd = true;
    defaultKeymap = "viins";
    dotDir = ".config/zsh";
    history = {
      extended = true;
      ignoreDups = true;
      ignorePatterns = [ "rm *" "pkill *" ];
      ignoreSpace = false;
    };
    initExtra =
      /* Turns a list into a single string. */
      builtins.concatStringsSep "\n" (map (x: "setopt ${x}") zshOptionsToSet)
      +
      ''
                  # Enable vim editing of command line
                  ${builtins.readFile ./plugins/01-vim-edit.zsh}
                  # Enable cd +1..9 to go back in dir stack
                  ${builtins.readFile ./plugins/02-cd.zsh}
                  # fzf bindings
                  source ${pkgs.fzf}/share/fzf/key-bindings.zsh

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

                  # Use vim keys in tab complete menu
                  zmodload zsh/complist
                  bindkey -M menuselect 'h' vi-backward-char
                  bindkey -M menuselect 'k' vi-up-line-or-history
                  bindkey -M menuselect 'l' vi-forward-char
                  bindkey -M menuselect 'j' vi-down-line-or-history
                  bindkey -M menuselect '^ ' accept-line

                  # Add entry by "+" but do not exit menuselect
                  bindkey -M menuselect "+" accept-and-menu-complete

                  # Color the completions
                  autoload -Uz compinit
                  zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:l
        ower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'
                  zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
                  zstyle ':completion:*' menu select

                  # Automatically escape urls when pasting
                  autoload -Uz url-quote-magic
                  zle -N self-insert url-quote-magic
                  autoload -Uz bracketed-paste-magic
                  zle -N bracketed-paste bracketed-paste-magic

                  # Custom plugins can be quickly loaded if fpath is extended:
                  fpath=(${./plugins} $fpath)
                  # Bookmarks by "@@"
                  autoload -Uz bookmarks.zsh && bookmarks.zsh
                  # Cursor mode block <> beam
                  autoload -Uz cursor_mode.zsh && cursor_mode.zsh

                  # alias that creates the directory and changes into it
                  mkcd(){ mkdir -p "$@" && cd "$@"; }

                  # Using zsh highlighting with long paths (like nix store) can be slow. This fixes it.
                  # found https://gist.github.com/magicdude4eva/2d4748f8ef3e6bf7b1591964c201c1ab
                  pasteinit() {
                    OLD_SELF_INSERT=''${''${(s.:.)widgets[self-insert]}[2,3]}
                    zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
                  }

                  pastefinish() {
                    zle -N self-insert $OLD_SELF_INSERT
                  }
                  zstyle :bracketed-paste-magic paste-init pasteinit
                  zstyle :bracketed-paste-magic paste-finish pastefinish

                  # Make comments visible on default background
                  ZSH_HIGHLIGHT_STYLES[comment]='none'

                  # Alternative display for when I am in nix shell
                  # Also preserves zsh when entering nix shelll
                  ${pkgs.any-nix-shell}/bin/any-nix-shell zsh --info-right | source /dev/stdin
      ''
      + # set SSH_AUTH_SOCK <=> gpg-agent is enabled in home-manager
      (if config.services ? gpg-agent.enable  # "?" is used so that lack of gpg-agent option does not cause an error
      then
        ''
          if [[ -z "$SSH_AUTH_SOCK" ]]; then
            export SSH_AUTH_SOCK="$(${config.programs.gpg.package}/bin/gpgconf --list-dirs agent-ssh-socket)"
          fi
        ''
      else "");

    shellAliases = {
      e = "$EDITOR";
      nvim = "$EDITOR";
      vim = "$EDITOR";
      ls = "${pkgs.exa}/bin/exa -h --group-directories-first --icons";
      l = "ls";
      ll = "ls -l";
      la = "ls -al";
      ka = "${pkgs.killall}/bin/killall";
      mkd = "mkdir -pv";
      ga = "${pkgs.git}/bin/git add";
      gau = "ga -u";
      grep = "grep --color=auto";
      mv = "mv -v";
      rm = "${pkgs.coreutils}/bin/rm -id";
      vidir = "${pkgs.moreutils}/bin/vidir --verbose";
      ccopy = "${pkgs.wl-clipboard}/bin/wl-copy";
      syu = "systemctl --user";
      cde = "cd /etc/nixos";
      lg = "${pkgs.lazygit}/bin/lazygit";
      # Colorize IP output
      ip = "ip -c";
    };
  };
  programs.direnv = {
    enable = true;
  };
  programs.starship = {
    enable = true;
    enableBashIntegration = false;
    enableFishIntegration = false;
    enableIonIntegration = false;
    enableNushellIntegration = false;
  };
}
# zsh (home-manager):2 ends here
