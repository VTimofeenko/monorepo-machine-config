{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.programs.vt-zsh;
in
{
  options.programs.vt-zsh = {
    starship_enable = mkOption {
      default = true;
      description = "Whether to enable starship.";
      type = lib.types.bool;
    };
    direnv_enable = mkEnableOption "enable direnv";
    gpg_enable = mkEnableOption "enable gpg-agent";
    enableAnyNixShell = mkEnableOption "enable any-nix-shell";
  };
  config = {
    environment.systemPackages = with pkgs; [
      fzf
      killall
      bat
      # bookmark plugin
      (writeTextFile {
        name = "bookmarks.zsh";
        text = ''${builtins.readFile ./plugins/bookmarks.zsh}'';
        destination = "/share/zsh/site-functions/bookmarks.zsh";
      })
      # My cursor plugin
      (writeTextFile {
        name = "cursor_mode.zsh";
        text = ''${builtins.readFile ./plugins/cursor_mode.zsh}'';
        destination = "/share/zsh/site-functions/cursor_mode.zsh";
      })
      # the next line conditionally installs direnv if it is enabled
      # just having pkgs.direnv is not enough, it does not get added to the path
    ] ++ (if cfg.direnv_enable then [ pkgs.direnv ] else [ ]);
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting = {
        enable = true;
      };
      shellAliases = {
        e = "$EDITOR"; # looks like 'vim' is needed here so that proper vimrc is being picked up
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
        lg = "lazygit";
        # Colorize IP output
        ip = "ip -c";
      };
      setOptions = [
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
      interactiveShellInit = ''
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
        zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':completion:*' menu select

        # Automatically escape urls when pasting
        autoload -Uz url-quote-magic
        zle -N self-insert url-quote-magic
        autoload -Uz bracketed-paste-magic
        zle -N bracketed-paste bracketed-paste-magic

        # Custom plugins (see call to pkgs.writeTextFile in the zsh.nix)
        # Bookmarks by "@@"
        autoload -Uz bookmarks.zsh && bookmarks.zsh
        # Cursor mode block <> beam
        autoload -Uz cursor_mode.zsh && cursor_mode.zsh

        # To use openpgp cards
        ${if cfg.gpg_enable
        then
          ''
          if (( $EUID != 0 )); then
            export GPG_TTY="$(tty)"
            ${pkgs.gnupg}/bin/gpg-connect-agent /bye
            export SSH_AUTH_SOCK="/run/user/$UID/gnupg/S.gpg-agent.ssh"
          fi
          ''
        else
          toString null
        }
        # alias that creates the directory and changes into it
        mkcd(){ mkdir -p "$@" && cd "$@"; }
      '';
      promptInit = ''
        ${if cfg.starship_enable
        then
          "eval \"$(${pkgs.starship}/bin/starship init zsh)\""
        else
          # reasonable default prompt
          "PROMPT=\"%F{white}%~ %(!.%B%F{red}#.%B%F{blue}>)%f%b\u00A0\""
        }
        ${if cfg.direnv_enable
        then
          "eval \"$(${pkgs.direnv}/bin/direnv hook zsh)\""
        else
          toString null
        }
        ${if cfg.enableAnyNixShell
          then
            "${pkgs.any-nix-shell}/bin/any-nix-shell zsh --info-right | source /dev/stdin"
          else
            toString null
         }
      '';
    };
  };
}
