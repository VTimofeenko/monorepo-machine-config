# home-manager clone of the OG zsh
{ pkgs, config, lib, ... }:
{
  home.packages = [
    pkgs.fzf
  ];
  programs.zsh =
    {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      enableSyntaxHighlighting = true;
      autocd = true;
      defaultKeymap = "viins";
      dotDir = ".config/zsh";
      history =
        {
          extended = true;
          ignoreDups = true;
          ignorePatterns = [ "rm *" "pkill *" ];
          ignoreSpace = false;
        };
      initExtra =
        ''
                    setopt BANG_HIST
                    setopt INTERACTIVE_COMMENTS
                    setopt HIST_VERIFY
                    setopt HIST_FCNTL_LOCK
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
        '';
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
  programs.starship =
    {
      enable = true;
      enableBashIntegration = false;
      enableFishIntegration = false;
      enableIonIntegration = false;
      enableNushellIntegration = false;
    };
}
