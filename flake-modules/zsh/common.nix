# A set of settings that are common for both modules
{ pkgs, pkgs-unstable }:
let
  inherit (pkgs.lib) getExe concatMapStringsSep concatStringsSep;
in
rec {
  # TODO: add alias for cd-ing into a package base directory. I seem to be doing that often
  # TODO: z for cd?
  # TODO: Better manpager
  # TODO: pass fzf completion

  # Shell aliases
  shellAliases = {
    e = "$EDITOR";
    nvim = "$EDITOR";
    vim = "$EDITOR";
    ls = "${getExe pkgs-unstable.eza} -h --group-directories-first --icons=auto";
    l = "ls";
    ll = "ls -l";
    la = "ls -al";
    ka = "${getExe pkgs.killall}";
    mkd = "mkdir -pv";
    ga = "${getExe pkgs.git} add";
    gau = "ga -u";
    grep = "grep --color=auto";
    mv = "mv -v";
    rm = "${pkgs.coreutils}/bin/rm -id";
    vidir = "${pkgs.moreutils}/bin/vidir --verbose";
    ccopy = if pkgs.stdenv.isDarwin then "pbcopy" else "${pkgs.wl-clipboard}/bin/wl-copy";
    syu = "systemctl --user";
    cde = "cd /etc/nixos";
    lg = "${getExe pkgs.lazygit}";
    # Colorize IP output
    ip = "ip -c";
    # Neat display of all relevant things in lsblk
    lsblk = "lsblk --topology --fs -o NAME,SIZE,TYPE,LABEL,UUID,FSAVAIL,FSUSE%,MOUNTPOINTS";
    # Quick nix repl with nixpkgs imported
    # NOTE: Uses channels-based nixpkgs
    # TODO: Make alias use this flake's nixpkgs
    nrn = "nix repl --expr 'import <nixpkgs>{}'";
  };
  # InteractiveShellInit?
  # List of shell-only packages
  packages = builtins.attrValues {
    inherit (pkgs)
      fzf# fuzzy finder. Installed for completions.
      bat# cat with wings!
      jq# parsing some JSON
      direnv# controls environments in projects
      curl# does not need introduction
      wget# neither does this
      fd# find replacement with saner syntax
      inetutils# a couple of utilities to be kept offline
      moreutils# a collection of additional tools
      busybox# yet another kitchen sink collection of tools
      ripgrep# useful grep replacement
      lsof# shows file handles
      dig# quick DNS tester
      unzip# unpacks archives
      htop# system monitoring
      ;
    inherit (pkgs-unstable)
      spacer# Useful for tailing logs
      # eza# ls replacement. Installed for completions
      ;
  };
  additionalOptions = [
    "INTERACTIVE_COMMENTS" # Bash-style comments in interactive shell
  ]
  ++
  [
    "BANG_HIST" # Log !!-like commands
    "INC_APPEND_HISTORY" # Write to the history file immediately, not when the shell exits.
    "HIST_VERIFY" # Don't execute immediately upon history expansion.
    "HIST_FCNTL_LOCK" # enable fcntl syscall for saving history
  ];
  initExtra =
    concatStringsSep "\n" [
      # Enable all options
      (concatMapStringsSep "\n" (opt: "setopt ${opt}") additionalOptions)
      # Source default fzf bindings
      # TODO: style fzf
      "source ${pkgs.fzf}/share/fzf/key-bindings.zsh"
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
      # Escape URLs when pasting
      ''
        # Automatically escape urls when pasting
        autoload -Uz url-quote-magic
        zle -N self-insert url-quote-magic
        autoload -Uz bracketed-paste-magic
        zle -N bracketed-paste bracketed-paste-magic
      ''
      # alias that creates the directory and changes into it
      ''
        mkcd(){ mkdir -p "$@" && cd "$@"; }
      ''
      # alias that cd-s into nix package's directory in store
      ''
        cdnixpkg(){ cd $(dirname $(which $1))}
      ''
      # Debug stuff
      ''
        _debug_show_completions(){
          for command completion in ''${(kv)_comps:#-*(-|-,*)}
          do
            printf "%-32s %s\n" $command $completion
          done | sort | less
        }
      ''
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
        zstyle :bracketed-paste-magic paste-finish pastefinish
      ''
      # NOTE: 23.11 -- move this to zsh syntaxHighlighting styles
      # TODO: make this mimick vim? Needs semantic colors
      ''
        # Source
        # https://github.com/zsh-users/zsh-syntax-highlighting/issues/359
        typeset -gA ZSH_HIGHLIGHT_STYLES
        ZSH_HIGHLIGHT_STYLES[comment]='fg=7'
      ''
      # Allows searching for completion
      # ''
      #   zstyle ':completion:*:*:*:default' menu yes select search
      # ''
    ]
  ;
  completionInit = ''
    autoload -U compinit && compinit -C -i
  '';
  plugins = {
    baseDir = ./myPlugins;
    list = [ "vim-edit" "cd-stack" "bookmarks" "cursor_mode" ];
  };
}
